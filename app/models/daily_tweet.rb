class DailyTweet
  include Mongoid::Document
  #include Mongoid::MapReduce

  field :total, :type => Integer
  field :created_at, :type => Time
  field :follower, :type => Integer

  index :created_at
  index [[:created_at, Mongo::DESCENDING]]

  belongs_to :keyword

  cache

end
