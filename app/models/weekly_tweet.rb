class WeeklyTweet
  include Mongoid::Document

  field :total, :type => Integer
  field :start_at, :type => Time
  field :end_at, :type => Time

  index :start_at
  index :end_at
  index [[:end_at, Mongo::DESCENDING]]

  belongs_to :keyword

  cache

  def self.filtered_by options
    self.where(:start_at.gte => options[:start_date]).and(:end_at.lte => options[:end_date])
  end

  def self.filter_by_week options
    self.where(:end_at.gte => options[:start_date]).and(:end_at.lte => options[:end_date])
  end
  
end
