module Rightboat
  class Statistics

    def self.monthly_boat_stats(boat)
      views = get_monthly_boat_views(boat)
      questions = get_monthly_questions(boat)

      ret = {}
      (0..11).each do |month_num|
        months_ago = (11-month_num).months.ago
        month_key = months_ago.to_s(:db)[0..6]
        month_name = months_ago.strftime("%b %y")
        stat = {views: 0, contacts: 0, questions: 0, label: month_name}
        stat[:views] = views[month_key] if views[month_key]
        stat[:questions] = questions[month_key] if questions[month_key]

        ret[month_key] = stat
      end

      ret
    end

    private

    def self.get_monthly_questions(boat)
      questions = {}
      Lead.where(boat_id:boat.id).group("YEAR(created_at), MONTH(created_at)").select("count(boat_id) as questions, concat(YEAR(created_at), '-', LPAD(MONTH(created_at), 2, '0')) as asked_at").each do |row|
        questions[row.asked_at] = row.questions
      end
      questions
    end

    def self.get_monthly_boat_views(boat)
      views = {}
      UserActivity.where(boat_id: boat.id, kind: :boat_view).group("YEAR(created_at), MONTH(created_at)").select("count(boat_id) as views, concat(YEAR(created_at), '-', LPAD(MONTH(created_at), 2, '0')) as viewed_at").each do |row|
        views[row.viewed_at] = row.views
      end
      views
    end

    def self.mongodb
      @_mongodb ||= Mongo::Client.new(Figaro.env.mongo_url)
    end

  end

end
