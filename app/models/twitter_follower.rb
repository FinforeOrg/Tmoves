class TwitterFollower
  include Mongoid::Document
  field :follower, :type => Integer
  field :created_at, :type => Time
  
  belongs_to :tweet_user
  belongs_to :keyword
end
