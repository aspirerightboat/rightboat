module Rightboat
  class Statistics

    ##
    ## public methods to be used often
    ##

    def self.monthly_boat_stats(boat)
      # registering the hit is done in BoatIntelligence (as it's just more there)
      views = get_monthly_boat_views(boat)
      contacts = get_monthly_seller_contact_views(boat)
      questions = get_monthly_questions(boat)

      ret = {}
      (0..11).each do |month_num|
        months_ago = (11-month_num).months.ago
        month_key = months_ago.to_s(:db)[0..6]
        month_name = months_ago.strftime("%b %y")
        stat = {views: 0, contacts: 0, questions: 0, label: month_name}
        stat[:views] = views[month_key] if views[month_key]
        stat[:contacts] = contacts[month_key] if contacts[month_key]
        stat[:questions] = questions[month_key] if questions[month_key]

        ret[month_key] = stat
      end

      ret
    end

    def self.get_seller_contact_views_in(member, period = 7)
      member_id = member.respond_to?(:id) ? member.id : member.to_i
      db = mongodb
      from_date = (Date.today - period).to_time
      to_date = Date.today.to_time
      result = db["seller_contact_views"].find.aggregate(
        [
          { :$match => { member_id: member_id, visited_at: { :$gte => from_date, :$lt => to_date } } },
          { :$group => { _id: '$member_id', views: {:$sum => :$views} } }
        ]
      ).find.first
      result ? result['views'].to_i : 0
    end

    def self.get_featured_views_in(member, period = 7, group_by = :boat)
      member_id = member.respond_to?(:id) ? member.id : member.to_i
      db = mongodb

      from_date = (Date.today - period).to_time
      to_date = Date.today.to_time

      group_key = (group_by.to_sym == :boat) ? '$boat_id' : '$member_id'

      pipes = [
        {'$match' => { member_id: member_id, viewed_at: { '$gte' => from_date, '$lt' => to_date}}},
        {'$group' => {_id: group_key, views: {'$sum' => '$views'}}},
        {'$sort' => { views: -1 }}
      ]
      ret = db['featured_boat_views'].find.aggregate(pipes).inject({}){|h, x| h[x['_id'].to_i] = x['views'].to_i; h}
      (group_by.to_sym == :boat) ? ret : ret.values.first.to_i
    end

    def self.get_featured_clicks_in(member, period = 7, group_by = :boat)
      member_id = member.respond_to?(:id) ? member.id : member.to_i
      db = mongodb

      from_date = (Date.today - period).to_time
      to_date = Date.today.to_time

      group_key = (group_by.to_sym == :boat) ? '$boat_id' : '$member_id'

      pipes = [
        {'$match' => { member_id: member_id, clicked_at: { '$gte' => from_date, '$lt' => to_date}}},
        {'$group' => {_id: group_key, clicks: {'$sum' => '$clicks'}}},
        {'$sort' => { views: -1 }}
      ]
      ret = db['featured_boat_clicks'].find.aggregate(pipes).inject({}){|h, x| h[x['_id'].to_i] = x['clicks'].to_i; h}
      (group_by.to_sym == :boat) ? ret : ret.values.first.to_i
    end

    def self.get_monthly_seller_contact_views(boat)
      boat_id = boat.respond_to?(:id) ? boat.id : boat.to_i
      db = mongodb

      from_date = Date.today - 365

      db["seller_contact_views"].find.aggregate(
        [
          { :$match => { boat_id: boat_id, viewed_at: { :$gte => from_date.to_time } } },
          { :$group => { _id: '$month', views: { :$sum => "$views" } } }
        ]
      ).to_a.inject({}) {|h, x| h[x['_id']] = x['views'].to_i; h}
    end

    def self.get_monthly_questions(boat)
      questions = {}
      Lead.where(boat_id:boat.id).group("YEAR(created_at), MONTH(created_at)").select("count(boat_id) as questions, concat(YEAR(created_at), '-', LPAD(MONTH(created_at), 2, '0')) as asked_at").each do |row|
        questions[row.asked_at] = row.questions
      end
      questions
    end

    def self.get_monthly_boat_views(boat)
      boat_id = boat.respond_to?(:id) ? boat.id : boat.to_i
      db = mongodb

      from_date = Date.today - 365

      pipes = [
        {"$match" => {boat_id: boat_id, viewed_at: {"$gte" => from_date.to_time} }},
        {"$group" => {_id: "$month", views: {"$sum" => "$count"}}},
        {"$sort" => {_id: -1}}
      ]
      db['boat_hits'].find.aggregate(pipes).inject({}) {|h, x| h[x['_id']] = x['views'].to_i; h}
    end

    def self.daily_banner_views(banner)
      banner_id = banner.respond_to?(:id) ? banner.id : banner.to_i
      db = mongodb

      from_date = Date.today - 31


      data = db["banner_views"].find.aggregate(
        [
          { :$match => { banner_id: banner_id, action_at: { :$gte => from_date.to_time } } },
          { :$group => { _id: '$date', views: {:$sum => :$views}, clicks: {:$sum => :$clicks} } }
        ]
      ).find.to_a

      ret = {}
      (0..31).each do |day_num|
        days_ago = (31-day_num).days.ago.to_date
        day_key = days_ago.to_s(:db)
        day_name = days_ago.strftime("%d %b")
        entry = data.select{|x| x['date'] == day_key}.first
        if entry
          ret[day_key] = {clicks: entry["clicks"].to_i, views: entry["views"].to_i, label: day_name}
        else
          ret[day_key] = {clicks: 0, views: 0, label: day_name}
        end
      end

      ret
    end

    def self.banner_views_in_one_month(banner)
      banner_id = banner.respond_to?(:id) ? banner.id : banner.to_i
      db = mongodb

      last_month = Date.today - 1.month
      from_date = last_month.beginning_of_month
      to_date = last_month.end_of_month

      db["banner_views"].find.aggregate(
        [
          { :$match => { banner_id: banner_id, action_at: { :$gte => from_date.to_time, '$lte' => to_date.to_time } } },
          { :$group => { _id: '$banner_id', views: {:$sum => :$views}, clicks: {:$sum => :$clicks} } }
        ]
      ).find.to_a.first
    end

    def self.monthly_banner_views(banner)
      banner_id = banner.respond_to?(:id) ? banner.id : banner.to_i
      db = mongodb

      from_date = Date.today - 365

      data = db["banner_views"].find.aggregate(
        [
          { :$match => { banner_id: banner_id, action_at: { :$gte => from_date.to_time } } },
          { :$group => { _id: '$month', views: {:$sum => :$views}, clicks: {:$sum => :$clicks} } }
        ]
      ).find.to_a

      ret = {}

      (0..11).each do |month_num|
        months_ago = (11 - month_num).months.ago
        month_key = months_ago.to_s(:db)[0..6]
        month_name = months_ago.strftime("%b %y")
        entry = data.select{|x| x['month'] == month_key}.first
        if entry
          ret[month_key] = {clicks: entry["clicks"].to_i, views: entry["views"].to_i, label: month_name}
        else
          ret[month_key] = {clicks: 0, views: 0, label: month_name}
        end
      end

      ret
    end

    def self.weeks_stats_for_member(member)
      twitted_boats = get_twitted_boats_in(member, 7).select(:id).map(&:id)
      stats = {
        contacts: get_seller_contact_views_in(member),
        visits: get_visit_dealer_sites_in(member),
        views: get_viewed_boats_in(member, 7, :member),
        questions: get_questioned_boats_in(member, 7, :member),
        twitts: twitted_boats.count
      }

      featured_views = get_featured_views_in(member)
      featured_clicks = get_featured_clicks_in(member)
      questioned_boats = get_questioned_boats_in(member)
      viewed_boats = get_viewed_boats_in(member)

      active_boat_ids = (
      viewed_boats.keys +
        questioned_boats.keys +
        featured_views.keys +
        twitted_boats +
        featured_clicks.keys).uniq

      active_boat_ids.each do |id, _|
        next unless boat = member.boats.where(id: id).first
        stats[boat.id] = {
          boat: boat,
          views: viewed_boats[boat.id].to_i,
          featured_views: featured_views[boat.id].to_i,
          featured_clicks: featured_clicks[boat.id].to_i,
          questions: questioned_boats[boat.id].to_i,
          twitted: twitted_boats.include?(boat.id.to_i) ? "Yes" : "No"
        }
      end

      stats
    end

    def self.is_hot_boat?(boat)
      boat_id = boat.respond_to?(:id) ? boat.id : boat
      db = mongodb
      !db["hot_boats"].find(_id: boat_id).first.nil?
    rescue Mongo::ConnectionFailure
      Rails.logger.error("ERROR! Could not connect to MongoDB")
      false
    end

    ##
    ##  Recoring methods
    ##

    def self.record_featured_boat_view(boat)
      db = mongodb
      db["featured_boat_views"].update(
        {
          boat_id: boat.id.to_i,
          member_id: boat.member_id.to_i,
          viewed_at: Time.now
        },
        {"$inc" => {"views" => 1}},
        {upsert:true, multi: false}
      )
    rescue Mongo::ConnectionFailure
      Rails.logger.error("ERROR! Could not connect to MongoDB")
      false
    end

    def self.record_featured_boat_click(boat)
      db = mongodb
      db["featured_boat_clicks"].update(
        {
          boat_id: boat.id.to_i,
          member_id: boat.member_id.to_i,
          clicked_at: Time.now
        },
        {"$inc" => {"clicks" => 1}},
        {upsert:true, multi: false}
      )
    rescue Mongo::ConnectionFailure
      Rails.logger.error("ERROR! Could not connect to MongoDB")
      false
    end

    def self.record_visit_dealer_site(boat_id, member_id)
      db = mongodb
      db["dealer_site_visits"].update(
        {
          boat_id: boat_id.to_i,
          member_id: member_id.to_i,
          visited_at: Time.now
        },
        {"$inc" => {"visits" => 1}},
        {upsert:true, multi: false}
      )
    rescue Mongo::ConnectionFailure
      Rails.logger.error("ERROR! Could not connect to MongoDB")
      false
    end

    def self.record_seller_contact_view(boat)
      db = mongodb
      viewed_at = Time.now

      db["seller_contact_views"].update(
        {
          member_id: boat.member_id,
          boat_id: boat.id,
          month: viewed_at.strftime("%Y-%m"),
          viewed_at: viewed_at
        },
        { "$inc" => {"views" => 1} },
        { upsert: true, multi: false }
      )
    rescue Mongo::ConnectionFailure
      Rails.logger.error("ERROR! Could not connect to MongoDB")
      false
    end

    def self.record_banner_view(banner)
      db = mongodb
      action_at = Time.now
      db["banner_views"].update(
        {
          banner_id: banner.id,
          month: action_at.strftime('%Y-%m'),
          date: action_at.to_date.to_s(:db),
          action_at: action_at
        },
        { "$inc" => {"views" => 1} },
        { upsert: true, multi: false }
      )
    rescue Mongo::ConnectionFailure
      Rails.logger.error("ERROR! Could not connect to MongoDB")
      false
    end

    def self.record_banner_click(banner)
      db = mongodb
      action_at = Time.now
      db["banner_views"].update(
        {
          banner_id: banner.id,
          month: action_at.strftime("%Y-%m"),
          date: action_at.to_date.to_s(:db),
          action_at: action_at
        },
        { "$inc" => {"clicks" => 1} },
        { upsert: true, multi: false }
      )
    rescue Mongo::ConnectionFailure
      Rails.logger.error("ERROR! Could not connect to MongoDB")
      false
    end

    def self.record_boats_count_of(member, count, date = nil)
      db = mongodb
      member_id = member.respond_to?(:id) ? member.id : member.to_i

      db["boat_counts"].update(
        {
          member_id: member_id,
          date: (date || Date.today).to_date.to_time
        },
        { "$set" => { "count" => count.to_i } },
        { upsert: true, multi: false }
      )
    rescue Mongo::ConnectionFailure
      Rails.logger.error("ERROR! Could not connect to MongoDB")
      false
    end

    def self.update_hot_boats
      db = mongodb

      db['hot_boats'].remove
      self.hot_boat_ids.each do |hot_boat_id|
        db["hot_boats"].insert({ _id: hot_boat_id })
      end
      db["hot_boats"].ensure_index("_id")
    end

    def self.hot_boat_ids_of_last_day
      Rails.cache.fetch('rightboat.hot_boat_ids', expires_in:60.minutes, race_condition_ttl:60) do
        db = mongodb

        ignore_before = 1.day.ago.beginning_of_day.to_time
        ignore_after = 1.day.ago.end_of_day.to_time
        pipes = [
          {"$match" => {viewed_at: {'$gte' => ignore_before, '$lt' => ignore_after}}},
          {"$group" => {_id: "$boat_id", views: {"$sum" => "$count"}, total: {'$sum' => 1}}}
        ]
        total_cnt = db['boat_hits'].find.aggregate(pipes).count

        limit_cnt = (total_cnt * 10 / 100.0).ceil
        limit_cnt = 5 if limit_cnt < 5

        db['boat_hits'].find.aggregate(pipes + [
                                    {"$sort" => {views: -1}},
                                    {"$limit" => limit_cnt}
                                  ]).map{|c| c["_id"].to_i}
      end
    end

    def self.hot_boat_ids
      Rails.cache.fetch('rightboat.hot_boat_ids', expires_in:60.minutes, race_condition_ttl:60) do
        db = mongodb

        ignore_before = 7.days.ago.to_time
        pipes = [
          {"$match" => {viewed_at: {'$gte' => ignore_before}}},
          {"$group" => {_id: "$boat_id", views: {"$sum" => "$count"}, total: {'$sum' => 1}}}
        ]
        total_cnt = db['boat_hits'].find.aggregate(pipes).count

        limit_cnt = (total_cnt * 5 / 100.0).ceil
        limit_cnt = 5 if limit_cnt < 5

        db['boat_hits'].find.aggregate(pipes + [
                                    {"$sort" => {views: -1}},
                                    {"$limit" => limit_cnt}
                                  ]).map{|c| c["_id"].to_i}
      end
    rescue Mongo::ConnectionFailure
      Rails.logger.error("ERROR! Could not connect to MongoDB")
      []
    end

    def self.get_boats_count_of(member, date)
      db = mongodb
      member_id = member.respond_to?(:id) ? member.id : member.to_i

      record = db["boat_counts"].find(member_id: member_id, date: date.to_date.to_time).first
      if record
        return record['count']
      end
    rescue Mongo::ConnectionFailure
      Rails.logger.error("ERROR! Could not connect to MongoDB")
      nil
    end

    def self.boats_count_history(member, from = nil)
      db = mongodb
      from ||= 1.month.ago
      member_id = member.respond_to?(:id) ? member.id : member.to_i
      db["boat_counts"].find(
        member_id: member_id,
        date: { '$gt' => from.to_date.to_time }
      ).sort(:date).to_a
    rescue Mongo::ConnectionFailure
      Rails.logger.error("ERROR! Could not connect to MongoDB")
      []
    end

    def self.get_viewed_boats_in(member, period = 7, group_by = :boat)
      member_id = member.respond_to?(:id) ? member.id : member.to_i
      db = mongodb

      from_date = (Date.today - period).to_time
      to_date = Date.today.to_time

      group_key = (group_by.to_sym == :boat) ? '$boat_id' : '$member_id'

      pipes = [
        {'$match' => { member_id: member_id, viewed_at: { '$gte' => from_date, '$lt' => to_date}}},
        {'$group' => {_id: group_key, views: {'$sum' => '$count'}}},
        {'$sort' => { views: -1 }}
      ]
      ret = db['boat_hits'].find.aggregate(pipes).inject({}){|h, x| h[x['_id'].to_i] = x['views'].to_i; h}
      (group_by.to_sym == :boat) ? ret : ret.values.first.to_i
    end

    def self.get_twitted_boats_in(member, period = 7)
      member_id = member.respond_to?(:id) ? member.id : member.to_i

      from_date = Date.today - period
      to_date = Date.today

      Boat.where(member_id: member_id).
        where("boats.twitted_at >= ?", from_date).
        where("boats.twitted_at < ?", to_date)
    end

    def self.get_questioned_boats_in(member, period = 7, group_by = :boat)
      member_id = member.respond_to?(:id) ? member.id : member.to_i

      from_date = Date.today - period
      to_date = Date.today

      group_key = (group_by.to_sym == :member) ? "seller_questions.member_id" : "boats.id"
      Boat.joins(:seller_questions).
        select("count(seller_questions.id) as q_cnt, boats.id").
        where("boats.member_id = ?", member_id).
        where("seller_questions.created_at >= ?", from_date).
        where("seller_questions.created_at < ?", to_date).
        group(group_key).
        order("count(seller_questions.id) DESC").
        having("count(seller_questions.id) > 0").inject({}) {|h, b| h[b.id] = b[:q_cnt].to_i; h }
    end

    def self.get_visit_dealer_sites_in(member, period = 7)
      member_id = member.respond_to?(:id) ? member.id : member.to_i
      db = mongodb
      from_date = (Date.today - period).to_time
      to_date = Date.today.to_time
      result = db["dealer_site_visits"].find.aggregate(
        [
          { :$match => { member_id: member_id, visited_at: { :$gte => from_date, :$lt => to_date } } },
          { :$group => { _id: '$member_id', visits: {:$sum => :$visits} } }
        ]
      ).first
      result ? result['visits'].to_i : 0
    end

    private

    def self.mongodb
      @_mongodb ||= Mongo::Client.new(Figaro.env.mongo_url)
    end

    # def self.mongodb
    #   @_mongodb ||= Mongo::Client.new('mongodb://127.0.0.1:27017/rightboat_production')
    # end

  end

end
