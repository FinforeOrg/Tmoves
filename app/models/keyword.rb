class Keyword
  include Mongoid::Document
  field :title,  :type => String
  field :ticker, :type => String
  index :title
  index :ticker
  validates :title, :presence => true, :uniqueness => true
  
  has_many :daily_tweets,      :dependent => :destroy
  has_many :keyword_charts,    :dependent => :destroy
  has_many :keyword_traffics,  :dependent => :destroy
  has_and_belongs_to_many :keyword_categories, :index => true

  cache

  def filter_daily_by options
    return self unless options
    resources = self.daily_tweets.where(:created_at.gte => options[:start_date]).and(:created_at.lte => options[:end_date])
    return resources
  end
  
  def is_ticker?
    return self.title.match(/^[$]/) || !self.ticker.blank?
  end
  
  def price
    return self.ticker.blank? ? (self.title.match(/^[$]/) ? self.title : "") : self.ticker
  end
  
  def tweet_1vs6
    end_at = Time.now.utc.midnight.beginning_of_month
    start_at = end_at.ago(1.month)
    month1 = self.daily_tweets.where({:created_at => {"$gte" => start_at, "$lt" => end_at}})
    total_tweet_1month = month1.sum(:total)
    month6 = self.daily_tweets.where({:created_at => {"$gte" => end_at.ago(6.months), "$lt" => end_at}})
    total_tweet_6month = month6.sum(:total)
    days_6month = ((end_at - start_at) / 86400).to_i
    tweet_1vs6 = (total_tweet_1month / (total_tweet_6month/days_6month)) * 100
    return {:total_tweet_1month => total_tweet_1month, :tweet_1vs6 => tweet_1vs6}
  end
  
  def normal_vs_average
    last_daily_tweet = self.daily_tweets.desc(:created_at).first
    if last_daily_tweet.created_at >= Time.now.utc.midnight
      last_daily_tweet = self.daily_tweets.where({:created_at => {"$lt" => Time.now.utc.midnight}}).desc(:created_at).first
    end
    start_at = last_daily_tweet.created_at.midnight
    end_at = start_at.tomorrow
    tweet_7days  = self.daily_tweets.where({:created_at => {"$gte" => end_at.ago(7.days), "$lt" => end_at}})
    total_7days  = tweet_7days.sum(:total).to_i
    tweet_14days = self.daily_tweets.where({:created_at => {"$gte" => end_at.ago(14.days), "$lt" => end_at}})
    follower_14days = tweet_14days.sum(:follower).to_i
    average7 = (total_7days/7)
    if average7 == 0
      versus7 = 0
    else
      versus7 = (last_daily_tweet.total.to_i/average7)*100
    end
    average14 = (follower_14days/14)
    if average14 == 0
      versus14 = 0
    else
      versus14 = (last_daily_tweet.follower.to_i/average14)*100
    end
    return {:current_tweet => last_daily_tweet.total.to_i, 
            :current_follower => last_daily_tweet.follower.to_i,
            :versus7 => versus7,
            :versus14 => versus14
           }
  end

end
