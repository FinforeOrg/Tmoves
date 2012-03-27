module Finforenet
  module Jobs
    class Savetrack
      attr_accessor :task_id, :dictionaries,:log, :failed_count, :start_count_daily_at, :previous_id, :tweet_ids

      def initialize
        @failed_count = 0
        @previous_id = ""
        @log = Logger.new("#{RAILS_ROOT}/log/savetrack.log")
        @log.debug "INITIALIZED    : #{Time.now}"
        start_save
      end

      def start_save
        if tracking = TrackingResult.where({:_id => {"$nin" => Finforenet::RedisFilter.get_array_ids("rejected_tracks")}}).first
          prepare_tracking(tracking)
        else
          sleep(10)
          start_save
        end
        
        rescue => e
          problem_occured(e,tracking)
      end
      
      def check_daily_keyword(status)
        if status.created_at.to_time.utc >= @start_count_daily_at
          Resque.enqueue(Finforenet::Jobs::Bg::DailyKeyword)
        end
      end
      
      def remove_tracking(tracking)
        tracking.destroy
      end

      def prepare_tracking(tracking)
        status = YAML::load(tracking.tweets)
        if Finforenet::RedisFilter.push_data("savetrack", status.id.to_s)
          dictionary = tracking["dictionary"]
          @start_count_daily_at = Finforenet::Utils::Time.tomorrow(status.created_at)
          check_daily_keyword(status)
          remove_tracking(tracking)
          Finforenet::Jobs::TrackingTweet.new(status,dictionary)
          start_save
        else
          tweet = Secondary::TweetResult.where(:tweet_id => status.id.to_s).first
          if tweet
            remove_tracking(tracking)
          else
            Finforenet::RedisFilter.push_data("rejected_tracks",tracking.id.to_s)
          end
          sleep(2)
          start_save
        end
      end

      def problem_occured(e,tracking)
        @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
        @log.debug "Date     : #{Time.now}"
        @log.debug "Error Msg: " + e.to_s
        @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
        @failed_count += 1
        if e.to_s.match(/syntax error/i)
          if tracking
            tracking = TrackingResult.where({"_id" => tracking.id}).first
            remove_tracking(tracking) if tracking
          end
        end
        sleep(20)
        after_failed
      end
      
      def after_failed
        if @failed_count < 10
          start_save
        else
          Resque.enqueue(Finforenet::Jobs::Bg::Savetweetresult)
        end
      end
      
    end

  end
end
