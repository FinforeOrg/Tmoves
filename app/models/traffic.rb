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
end
