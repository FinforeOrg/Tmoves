class ChartType
  include Mongoid::Document
  field :title, :type => String
  field :days, :type => Integer
  field :weeks, :type => Integer
  field :months, :type => Integer
  field :display_legend, :type => Boolean
  field :total_average, :type => Boolean
  field :total_tweet, :type => Boolean
  field :total_follower, :type => Boolean
  field :category, :type => String

  has_many :keyword_charts, :dependent => :destroy
  validate :chart_period
  validate :chart_data
  validates :days, :numericality => true, :allow_blank => true
  validates :weeks, :numericality => true, :allow_blank => true
  validates :months, :numericality => true, :allow_blank => true

  protected
    def chart_period
      self.errors.add("days, weeks or months", " should be entered.") if self.days.blank? && self.weeks.blank? && self.months.blank?
    end

    def chart_data
      self.errors.add("You", " should select one or mix of total average, tweet or follower") if !self.total_average && !self.total_tweet && !self.total_follower
    end

end
