class KeywordTraffic
  include Mongoid::Document
  field :keyword_str,            :type => String
  
  #audience statistics
  field :audience_one_month,   :type => Integer
  field :audience_six_months,    :type => Integer
  field :audience_ten_weeks,     :type => Integer
  field :audience_seven_days,    :type => Integer
  field :audience_fourteen_days, :type => Integer
  
  #tweets statistic
  field :tweet_one_month,   :type => Integer
  field :tweet_six_months,    :type => Integer
  field :tweet_ten_weeks,     :type => Integer
  field :tweet_seven_days,    :type => Integer
  field :tweet_fourteen_days, :type => Integer
  
  field :tweet_total,    :type => Integer
  field :audience_total, :type => Integer
  field :created_at,     :type => Time
  
  index :keyword_id
  index([ [:created_on, Mongo::DESCENDING]], :background => true)

  belongs_to :keyword
  #after_create :after_creation
  
  def self.lastest_info
    #self.where({:tweet_one_month => {"$ne" => nil}, :tweet_six_months => {"$ne" => nil}}).desc(:created_at).first
    self.desc(:created_at).first
  end
  
  def self.since(start_at)
    self.where({:created_at => {"$gte" => start_at, "$lt" => start_at.tomorrow}})
  end
  
  # ******************************************************************
  # TWEET STATISTICS
  # ******************************************************************
    
  def tweet_health_seven_days
    healthy_calculator(self.tweet_total.to_f, tweet_average_seven_days)
  end
  
  def tweet_average_seven_days
    average_calculator(self.tweet_seven_days.to_f,7)
  end
  
  def tweet_health_fourteen_days
    healthy_calculator(self.tweet_total.to_f, tweet_average_fourteen_days)
  end
  
  def tweet_average_fourteen_days
    average_calculator(self.tweet_fourteen_days.to_f,14)
  end
  
  def tweet_health_ten_weeks
    healthy_calculator(self.tweet_total.to_f, tweet_average_ten_weeks)
  end
  
  def tweet_average_ten_weeks
    average_calculator(self.tweet_ten_weeks.to_f,70)
  end
  
  def tweet_health_six_months
    healthy_calculator(self.tweet_one_month.to_f, tweet_average_six_months)
  end
  
  def tweet_average_six_months
    average_calculator(self.tweet_six_months.to_f, 6)
  end
  
  def tweet_health_one_month
    healthy_calculator(self.tweet_total.to_f, tweet_average_one_month)
  end
  
  def tweet_average_one_month
    average_calculator(self.tweet_one_month.to_f, months_to_days(1))
  end
  
  # ******************************************************************
  #AUDIENCE STATISTICS
  # ******************************************************************
  
  def audience_health_seven_days
    healthy_calculator(self.audience_total.to_f, audience_average_seven_days)
  end
  
  def audience_average_seven_days
    average_calculator(self.audience_seven_days.to_f,7)
  end
  
  def audience_health_fourteen_days
    healthy_calculator(self.audience_total.to_f, audience_average_fourteen_days)
  end
  
  def audience_average_fourteen_days
    average_calculator(self.audience_fourteen_days.to_f,14)
  end
  
  def audience_health_ten_weeks
    healthy_calculator(self.audience_total.to_f, audience_average_ten_weeks)
  end
  
  def audience_average_ten_weeks
    average_calculator(self.audience_ten_weeks.to_f,70)
  end
  
  def audience_health_six_months
    healthy_calculator(audience_one_month.to_f, audience_average_six_months)
  end
  
  def audience_average_six_months
    average_calculator(self.audience_six_months.to_f, months_to_days(6))
  end
  
  def audience_health_one_month
    healthy_calculator(self.audience_total.to_f, audience_average_one_month)
  end
  
  def audience_average_one_month
    average_calculator(self.audience_one_month.to_f, months_to_days(1))
  end
  
  # ******************************************************************
  # UTILITIES OF STATISTICS
  # ******************************************************************
  
  def self.calculate_healthy(_total, _average)
    if _average > 0
      _result = (_total/_average)*100
    else
      _result = 0
    end
    return _result
  end
   
  def healthy_calculator(_total,_average)
    self.class.calculate_healthy(_total, _average)
  end
  
  def average_calculator(_total,_devider)
    _average = _total/_devider
    (_average <= 0) ? 0 : _average
  end
  
  def months_to_days(_range)
    end_date = self.created_at.to_date.beginning_of_month
    start_date = end_date.ago(_range.month).to_date
    return (end_date - start_date).to_i
  end

  def after_creation
    if self.class.where({:created_at => self.created_at}).count >= 113
      Member.all.each do |user|
        begin
          UserMailer.news_letter(user, self.created_at, self.created_at.tomorrow).deliver
        rescue => e
          @log = Logger.new("#{Rails.root}/log/daily_tweet.log")
          @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
          @log.debug "Keyword Traffic Model Line 163"
          @log.debug "Date     : #{Time.now}"
          @log.debug "Error Msg: " + e.to_s
          @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
        else
        end  
      end
    end
  end
   
end
