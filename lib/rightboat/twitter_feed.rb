
class Rightboat::TwitterFeed
  attr_accessor :image, :text, :screen_name, :retweeted, :created_at

  extend ActionView::Helpers
  extend Rails.application.routes.url_helpers

  def self.all(max_id = nil)
    Rails.cache.fetch "rightboat.recent_tweets.m#{max_id}", expires_in:5.minutes, race_condition_ttl:60 do
      options = max_id ? { max_id: max_id } : {}
      tweets = client.user_timeline(Figaro.env.twitter_handle, options)

      tweets.map do |tweet|
        self.new(tweet)
      end
    end
  rescue
    []
  end

  def self.full
    def collect_with_max_id(collection=[], max_id=nil, &block)
      response = yield(max_id)
      collection += response
      response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
    end

    def client.get_all_tweets(user)
      collect_with_max_id do |max_id|
        options = {count: 200, include_rts: true}
        options[:max_id] = max_id unless max_id.nil?
        user_timeline(user, options)
      end
    end
  end

  def self.client
    @_client ||= Twitter::REST::Client.new do |config|
      config.consumer_key    = Figaro.env.twitter_key
      config.consumer_secret = Figaro.env.twitter_secret
    end
  end

  def initialize(tweet)
    self.retweeted = tweet.retweeted?
    self.image = tweet.user.profile_image_url
    self.screen_name = tweet.user.screen_name
    self.text = tweet.text
    self.created_at = tweet.created_at
  end

  def self.send_reduced_boat(offset = 0)
    boat = Boat.where('previous_control_price_changed_at > ? AND reduced_percentage < ?', 1.day.ago.at_beginning_of_day, 40).order('reduced_percentage desc').offset(offset).limit(1).first
    if boat
      description = get_random_description(boat)
      if description
        client.update(description)
        boat.update_attribute(:twitted_at, Time.now)
        return description
      end
    else
      return nil
    end
  end

  def self.send_hot_boat
    hot_ids = Statistics.hot_boat_ids_of_last_day
    boat = Boat.member_active.where(id: hot_ids, twitted_at: nil).first
    if boat
      description = get_random_description(boat, :hot)
      if description
        Twitter.update(description)
        boat.update_attribute(:twitted_at, Time.now)
        return description
      end
    end
  end

  def self.send_featured_boat
    boat = Boat.member_active.featured(twitted_at: nil).first
    if boat
      description = get_random_description(boat, :featured)
      if description
        Twitter.update(description)
        boat.update_attribute(:twitted_at, Time.now)
        return description
      end
    end
  end

  def self.get_random_description(boat, t_group = :reduced)
    manufacturer = boat.manufacturer.name rescue nil
    model        = boat.model.name rescue nil
    year         = boat.year_built rescue nil
    url          = Shorturl.find_or_create_by_url(Rails.application.routes.url_helpers.boat_slug_url(boat.slug, host:"www.rightboat.com")).shorturl
    pc           = "#{boat.reduced_percentage}%" rescue nil
    age          = Time.now.year - boat.year_built rescue nil
    age_human    = pluralize(age, "year")

    if t_group == :reduced
      return nil if boat.reduced_percentage.nil? || boat.reduced_percentage == 0
    end

    descriptions_hash = {
        reduced: [
            "#{manufacturer} #{model} year reduced by #{pc} #{url}",
            "Discounted by #{pc} - #{manufacturer} #{model} #{url}",
            "This #{manufacturer} #{model} has been reduced by #{pc} #{url}",
            "Discount Alert: #{manufacturer} #{model} reduced by #{pc} #{url}",
            "Price Reduction: #{manufacturer} #{model} reduced by #{pc} #{url}",
            "#{url} <- reduced by #{pc}",
            "Boat #{manufacturer} #{model} reduced by #{pc}! Check it out now on #{url}",
            "We have a #{manufacturer} #{model} reduced by #{pc}. #{url}",
        ],
        hot: [
            "Todays HOT boat is #{url}",
            "The hottest boat today is #{url}",
            "#{url} is our most popular boat today",
            "The boat everyone is looking at - #{url}",
            "See why this boat is the most viewed in the last 24h - #{url}",
        ],
        featured: [
            "Today's featured boat is #{url}",
            "Featured boat of the day #{url}",
            "Check out our featured boat of the day #{url}"
        ]
    }

    descriptions = descriptions_hash[t_group]
    # Conditional descriptions
    if t_group == :reduced
      if (year)
        descriptions << "#{year} #{manufacturer} #{model} reduced by #{pc}. #{url}"
        descriptions << "#{pc} price reduction on a #{year} #{manufacturer} #{model} #{url}"
        descriptions << "This #{year} #{manufacturer} #{model} has been reduced by #{pc} - #{url}"
      end
      if (boat.reduced_percentage > 35)
        descriptions << "Major discount - #{manufacturer} #{model} reduced by #{pc}" # only apply if over 35%
      end
      if (age >= 0)
        if (age < 1)
          descriptions << "Nearly new #{manufacturer} #{model} reduced by #{pc}" # only display if less that 1 year old
        else
          descriptions << "#{age_human} old #{manufacturer} #{model} reduced by #{pc}. #{url}" # only display if 1 or more years old
        end
      end
    end

    descriptions.sample
  end
end
