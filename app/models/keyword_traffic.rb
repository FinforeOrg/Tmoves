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
  
  # ******************************************************************
  # TWEET STATISTICS
  # ******************************************************************
    
  def tweet_health_seven_days
    healthy_calculator(tweet_seven_days.to_f, tweet_average_seven_days)
  end
  
  def tweet_average_seven_days
    average_calculator(self.tweet_seven_days.to_f,7)
  end
  
  def tweet_health_fourteen_days
    healthy_calculator(tweet_average_fourteen_days.to_f, tweet_average_fourteen_days)
  end
  
  def tweet_average_fourteen_days
    average_calculator(self.tweet_fourteen_days.to_f,14)
  end
  
  def tweet_health_ten_weeks
    healthy_calculator(tweet_average_ten_weeks.to_f, tweet_average_fourteen_days)
  end
  
  def tweet_average_ten_weeks
    average_calculator(self.tweet_ten_weeks.to_f,70)
  end
  
  def tweet_health_six_months
    healthy_calculator(tweet_average_six_months.to_f, tweet_average_fourteen_days)
  end
  
  def tweet_average_six_months
    average_calculator(self.tweet_six_months.to_f, months_to_days(6))
  end
  
  def tweet_health_one_month
    healthy_calculator(tweet_average_one_month.to_f, tweet_average_fourteen_days)
  end
  
  def tweet_average_one_month
    average_calculator(self.tweet_six_months.to_f, months_to_days(1))
  end
  
  # ******************************************************************
  #AUDIENCE STATISTICS
  # ******************************************************************
  
  def audience_health_seven_days
    healthy_calculator(audience_seven_days.to_f, audience_average_seven_days)
  end
  
  def audience_average_seven_days
    average_calculator(self.audience_seven_days.to_f,7)
  end
  
  def audience_health_fourteen_days
    healthy_calculator(audience_average_fourteen_days.to_f, audience_average_fourteen_days)
  end
  
  def audience_average_fourteen_days
    average_calculator(self.audience_fourteen_days.to_f,14)
  end
  
  def audience_health_ten_weeks
    healthy_calculator(audience_average_ten_weeks.to_f, audience_average_fourteen_days)
  end
  
  def audience_average_ten_weeks
    average_calculator(self.audience_ten_weeks.to_f,70)
  end
  
  def audience_health_six_months
    healthy_calculator(audience_average_six_months.to_f, audience_average_fourteen_days)
  end
  
  def audience_average_six_months
    average_calculator(self.audience_six_months.to_f, months_to_days(6))
  end
  
  def audience_health_one_month
    healthy_calculator(audience_average_one_month.to_f, audience_average_fourteen_days)
  end
  
  def audience_average_one_month
    average_calculator(self.audience_one_months.to_f, months_to_days(1))
  end
  
  # ******************************************************************
  # UTILITIES OF STATISTICS
  # ******************************************************************
   
  def healthy_calculator(_total,_average)
    if _average > 0
      _result = (_total/_average)*100
    else
      _result = 0
    end
    return _result
  end
  
  def average_calculator(_total,_devider)
    _average = _total/_devider
    (_average <= 0) ? 0 : _average
  end
  
  def months_to_days(_range)
    end_date = self.created_at.to_date.beginning_of_month
    start_date = end_date.ago(_range.month)
    return (end_date - start_date).to_i
  end
   
end
