class DailyTweet
  include Mongoid::Document
  #include Mongoid::MapReduce

  field :total, :type => Integer
  field :created_at, :type => Time
  field :follower, :type => Integer

  index :created_at
  index [[:created_at, Mongo::DESCENDING]]
  index :keyword_id

  belongs_to :keyword

  #cache
  
  def self.save_total_and_follower(created_at, total_follower, keyword_id)
    midnight = created_at.utc.midnight
    search_options = {:created_at => {"$gte" => midnight, "$lt" => midnight.tomorrow}, 
                      :keyword_id => keyword_id}
    daily_tweet = self.where(search_options).first
    if daily_tweet
      daily_tweet.inc(:total, 1)
      daily_tweet.inc(:follower, total_follower)
    else
      DailyTweet.create({:keyword_id => self.id, 
                         :total      => 1, 
                         :follower   => total_follower, 
                         :created_at => midnight})
    end
  end
  
  def self.find_keyword_periode(keyword_id, start_at, end_at)
    self.where({:created_at => {"$gte" => start_at, "$lt" => end_at}, :keyword_id => keyword_id})
  end

end
