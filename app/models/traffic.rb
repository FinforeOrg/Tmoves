class Traffic
  include Mongoid::Document
  field :title, :type => String
  index :title

  has_many :keyword_traffics
  
  def self.audiences
    self.where(:title=>/audience/i).first.keyword_traffics
  end
  
  def self.tweets
    self.where(:title=>/tweet/i).first.keyword_traffics
  end
  
  def self.audience_id
    self.where(:title=>/audience/i).first.id
  end
  
  def self.tweet_id
    self.where(:title=>/tweet/i).first.id
  end
end
