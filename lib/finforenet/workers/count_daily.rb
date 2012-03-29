module Finforenet
  module Workers
    class CountDaily
      attr_accessor :failed_tasks, :log, :keywords 
      attr_accessor :limit_at, :start_at, :conter

      def initialize(datetime = nil)
       @failed_tasks = []
       @counter = 0
       @limit_at = get_limit_at(datetime) if datetime.present?
       start_count_keywords
      end
      
      def get_limit_at(datetime)
        Time.at(datetime.to_i).utc.midnight
      end
      
      def get_static_keywords
        Keyword.all.map{|key| {:id => key.id, :title => key.title} }
      end

      def start_count_keywords
        @keywords = get_static_keywords
        count_6_monts_ago
      end
      
      def dt_opts(keyword_id, start_at, end_at)
        {:keyword_id => keyword_id, :created_at => {"$gte" => start_at, "$lt" => end_at}}
      end
      
      def get_daily_tweets(keyword_id, start_at, end_at)
        opt = dt_opts(keyword_id, start_at, end_at)
        daily_tweets = DailyTweet.where(opt)
        _total = daily_tweets.sum(:total).to_i
        _audience = daily_tweets.sum(:follower).to_i
        return {:total => _total, :audience => _audience}
      end
      
      def midnight
        Time.now.utc.midnight
      end
      
      def is_beginning_month?
        @limit_at.to_i == midnight.at_beginning_of_month.to_i
      end
      
      def is_monday?
        @limit_at.to_i == midnight.monday.to_i
      end
      
      def start_analyst
        audience_id = Traffic.audience_id
        tweet_id = Traffic.tweet_id
        @keywords.each do |keyword|
          if is_beginning_month?
            count_6_months(audience_id, tweet_id, keyword[:id])
            count_1_month(audience_id, tweet_id, keyword[:id])
          end
          if is_monday?
            count_10_weeks(audience_id, tweet_id, keyword[:id])
          end
          count_14_days(audience_id, tweet_id, keyword[:id])
          count_7_days(audience_id, tweet_id, keyword[:id])
        end
		email_daily_report
      end
      
      def count_6_months(audience_id, tweet_id, keyword_id)
        end_at = @limit_at.at_beginning_of_month
        start_at = end_at.ago(6.months)
        count_data(:month6, start_at, end_at, audience_id, tweet_id, keyword_id)
      end
      
      def count_1_month(audience_id, tweet_id, keyword_id)
        end_at = @limit_at.at_beginning_of_month
        start_at = end_at.ago(1.month)
        count_data(:month1, start_at, end_at, audience_id, tweet_id, keyword_id)
      end
      
      def count_10_weeks(audience_id, tweet_id, keyword_id)
        end_at = @limit_at.monday
        start_at = end_at.ago(10.weeks)
        count_data(:week10, start_at, end_at, audience_id, tweet_id, keyword_id)
      end
	  
	  def count_14_days(audience_id, tweet_id, keyword_id)
        end_at = @limit_at.tomorrow
        start_at = end_at.ago(14.days)
        count_data(:day14, start_at, end_at, audience_id, tweet_id, keyword_id)
      end
	  
	  def count_7_days(audience_id, tweet_id, keyword_id)
        end_at = @limit_at.tomorrow
        start_at = end_at.ago(7.days)
        count_data(:day7, start_at, end_at, audience_id, tweet_id, keyword_id)
      end
      
      def count_data(attribute, start_at, end_at, audience_id, tweet_id, keyword_id)
        tweet = get_daily_tweets(keyword_id, start_at, end_at)
        tweet_traffic = KeywordTraffic.where({:keyword_id => keyword_id, :traffic_id => tweet_id}).first
        tweet_traffic.update_attribute(attribute, tweet[:total].to_i) if tweet_traffic
        audience_traffic = KeywordTraffic.where({:keyword_id => keyword_id, :traffic_id => audience_id}).first
        audience_traffic.update_attribute(attribute, tweet[:audience].to_i) if audience_traffic
      end

      def on_failed(e)
        @log = Logger.new("#{RAILS_ROOT}/log/daily_tweet.log")
        @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
        @log.debug "Date     : #{Time.now}"
        @log.debug "Error Msg: " + e.to_s
        @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
      end

      def random_timer
        return rand(10) + 5
      end  

      def email_daily_report
        #Member.all.each do |user|
          user = Member.first
          UserMailer.news_letter(user).deliver  
          rescue => e
            on_failed(e)
        #end
        #Resque.redis.del "queue:Savetweetresult"
        #Resque.enqueue_in(1.days, Finforenet::Jobs::Bg::DailyKeyword)
        #expire_action :controller => :home, :action => :categories_tab
      end

    end
  end
end
