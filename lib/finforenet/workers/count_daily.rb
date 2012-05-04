module Finforenet
  module Workers
    class CountDaily
      attr_accessor :failed_tasks, :log, :keywords, :is_emailed
      attr_accessor :limit_at, :start_at, :end_at, :conter

      def initialize(datetime = nil)
         @failed_tasks = []
         @counter = 0
         @is_emailed = false
         @limit_at = datetime if datetime.present?
         start_count_keywords
      end
      
      def start_count_keywords
        @keywords = get_static_keywords
        last_dt_at = DailyTweet.desc(:created_at).first.created_at.utc.midnight
        first_tr_at = TrackingResult.asc(:created_at).first.created_at.utc.midnight
        if first_tr_at > last_dt_at
          @start_at = first_tr_at
        else
          @start_at = last_dt_at
        end
        @start_at = @start_at.yesterday if @start_at > Time.now.utc.midnight
        @end_at   = @start_at.tomorrow
        start_recursive
      end
      
      def start_recursive
        if counter < @keywords.count
          keyword = @keywords[@counter]
          opts = dt_opts(keyword[:id])
          keyword_traffic = KeywordTraffic.where(opts).first
          if keyword_traffic.blank?
            daily_tweet = DailyTweet.where(opts).first
            if daily_tweet
              populate_keyword_traffic(daily_tweet,keyword)
            else
              #continue_recursive
              populate_daily_tweet(keyword,started_at,ended_at)
            end
          else
            keyword_traffic = KeywordTraffic.asc(:created_at).first
            @started_at = keyword_traffic.created_at.utc.midnight.yesterday
            @ended_at = started_at.tomorrow
            start_recursive(started_at, ended_at)
          end
        else
          recovery_error
        end
      end
      
      def count_six_months(keyword_traffic_id, keyword_id)
        ended_at = @start_at.at_beginning_of_month
        started_at = ended_at.ago(6.months)
        tweet_data = get_daily_tweets(keyword_id, started_at, ended_at)
        keyword_traffic = KeywordTraffic.where(:_id => keyword_traffic_id).first
        if keyword_traffic
          metadata = {:audience_six_months => tweet_data[:audience], :tweet_six_months => tweet_data[:total]}
          keyword_traffic.update_attributes(metadata)
          count_one_month(keyword_traffic_id, keyword_id)
        end
        rescue => e
          on_failed(e, keyword_traffic_id, keyword_id, "count_six_months")
      end
      
      def count_one_month(keyword_traffic_id, keyword_id)
        ended_at = @start_at.at_beginning_of_month
        started_at = ended_at.ago(1.month)
        tweet_data = get_daily_tweets(keyword_id, started_at, ended_at)
        keyword_traffic = KeywordTraffic.where(:_id => keyword_traffic_id).first
        if keyword_traffic
          metadata = {:audience_one_month => tweet_data[:audience], :tweet_one_month => tweet_data[:total]}
          keyword_traffic.update_attributes(metadata)
          count_ten_weeks(keyword_traffic_id, keyword_id)
        end
        rescue => e
          on_failed(e, keyword_traffic_id, keyword_id, "count_one_month")
      end
      
      def count_ten_weeks(keyword_traffic_id, keyword_id)
        ended_at = @start_at.monday
        started_at = ended_at.ago(10.weeks)
        tweet_data = get_daily_tweets(keyword_id, started_at, ended_at)
        keyword_traffic = KeywordTraffic.where(:_id => keyword_traffic_id).first
        if keyword_traffic
          metadata = {:audience_ten_weeks => tweet_data[:audience], :tweet_ten_weeks => tweet_data[:total]}
          keyword_traffic.update_attributes(metadata)
          count_seven_days(keyword_traffic_id, keyword_id)
        end
        rescue => e
          on_failed(e, keyword_traffic_id, keyword_id, "count_ten_weeks")
      end
      
      def count_seven_days(keyword_traffic_id, keyword_id)
        ended_at = @start_at.tomorrow
        started_at = ended_at.ago(14.days)
        tweet_data = get_daily_tweets(keyword_id, started_at, ended_at)
        keyword_traffic = KeywordTraffic.where(:_id => keyword_traffic_id).first
        if keyword_traffic
          metadata = {:audience_seven_days => tweet_data[:audience], :tweet_seven_days => tweet_data[:total]}
          keyword_traffic.update_attributes(metadata)
          count_fourteen_days(keyword_traffic_id, keyword_id)
        end
        rescue => e
          on_failed(e, keyword_traffic_id, keyword_id, "count_seven_days")
      end
      
      def count_fourteen_days(keyword_traffic_id, keyword_id)
        ended_at = @started_at.tomorrow
        started_at = ended_at.ago(14.days)
        tweet_data = get_daily_tweets(keyword_id, started_at, ended_at)
        keyword_traffic = KeywordTraffic.where(:_id => keyword_traffic_id).first
        if keyword_traffic
          metadata = {:audience_fourteen_days => tweet_data[:audience], :tweet_fourteen_days => tweet_data[:total]}
          keyword_traffic.update_attributes(metadata)
          continue_recursive
        end
        rescue => e
          on_failed(e, keyword_traffic_id, keyword_id, "count_fourteen_days")
      end
      
      def on_failed(e, keyword_traffic_id, keyword_id, task_function)
        write_error_in_logfile(e)
        FailedDailyTask.create({:keyword_id         => keyword_id,
                                :keyword_traffic_id => keyword_traffic_id,
                                :start_at           => @started_at,
                                :end_at             => @end_at,
                                :error_message      => e.to_s,
                                :task_function      => task_function
                              })
        sleep(random_timer)
        continue_recursive
      end
      
      def continue_recursive
        @counter += 1
        start_recursive
      end
      
      def recovery_error
        failed_task = FailedDailyTask.first
        if failed_task
          @start_at = failed_task.start_at
          @end_at = failed_task.end_at
          send(failed_task.task_function, failed_task.keyword_traffic_id, failed_task.keyword_id)
        else
          email_daily_report unless @is_emailed
        end
      end

      def random_timer
        return rand(10) + 5
      end  

      def email_daily_report
        @is_emailed = true
        #Member.all.each do |user|
          user = Member.first
          UserMailer.news_letter(user, @started_at, @ended_at).deliver  
          rescue => e
            write_error_in_logfile(e)
        #end
      end
      
        def get_limit_at(datetime)
          Time.at(datetime.to_i).utc.midnight
        end
        
        def get_static_keywords
          Keyword.all.map{|key| {:id => key.id, :title => key.title} }
        end
        
        def dt_opts(keyword_id)
          {:keyword_id => keyword_id, :created_at => {"$gte" => @start_at, "$lt" => @end_at}}
        end
        
        def get_daily_tweets(keyword_id, started_at, ended_at)
          daily_tweets = DailyTweet.where({:keyword_id => keyword_id, 
                                           :created_at => {"$gte" => started_at, "$lt" => ended_at}})
          _total = daily_tweets.sum(:total).to_i
          _audience = daily_tweets.sum(:follower).to_i
          return {:total => _total, :audience => _audience}
        end
        
        def midnight
          Time.now.utc.midnight
        end
        
        def populate_daily_tweet(keyword)
          opts = {:keyword_arr.in => [keyword[:title].downcase], 
                  :created_at => {"$gte" => @start_at, "$lt" => @end_at}}
          trackings = TrackingResult.where(opts)
          total = trackings.count
          audience = trackings.sum(:audience)
          daily_tweet = DailyTweet.create({:keyword_id => keyword[:id], 
                                           :total      => total, 
                                           :follower   => audience, 
                                           :created_at => @start_at})
          populate_keyword_traffic(daily_tweet,keyword)
        end
        
        def populate_keyword_traffic(daily_tweet,keyword)
          traffic = {:created_at     => @start_at,
                     :tweet_total    => daily_tweet.total.to_i,
                     :audience_total => daily_tweet.follower.to_i,
                     :keyword_id     => keyword[:id],
                     :keyword_str    => keyword[:title]
                    }
          keyword_traffic = KeywordTraffic.create(traffic)
          keyword_traffic_id = keyword_traffic.id
          count_six_months(keyword_traffic_id, keyword[:id])
        end
        
        def write_error_in_logfile(e)
          @log = Logger.new("#{RAILS_ROOT}/log/daily_tweet.log")
          @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
          @log.debug "Date     : #{Time.now}"
          @log.debug "Error Msg: " + e.to_s
          @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
        end

    end
  end
end
