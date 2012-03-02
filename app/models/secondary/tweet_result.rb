class Secondary::TweetResult
  include Mongoid::Document
  set_database :secondary

  field :tweet_id, :type => String
  field :retweet_count, :type => Integer
  field :coordinates, :type => String
  field :geo, :type => String
  field :place, :type => String
  field :source, :type => String
  field :created_at, :type => Time
  field :tweet_text, :type => String
  field :keywords, :type => String
  field :lang, :type => String
  field :audience, :type => Integer

  index :created_at
  index :keywords
  index :tweet_id
  index :tweet_text
  index [[:created_at, Mongo::DESCENDING]]
  shard_key :keywords, :created_at

  belongs_to :tweet_user

  #cache

  def to_indexed_json
    self.to_json(:include => :tweet_user)
  end
  
  def self.StartAt
    "01/01/2012".to_time.utc.midnight
  end

end
