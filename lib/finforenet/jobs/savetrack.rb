module Finforenet
  module Jobs
    class Savetrack
      attr_accessor :task_id, :rejected_ids, :dictionaries,:log, :failed_count, :start_count_daily_at, :previous_id, :tweet_ids

      def initialize
        @failed_count = 0
        @previous_id = ""
        @log = Logger.new("#{RAILS_ROOT}/log/stream.log")
        @log.debug "INITIALIZED    : #{Time.now}"
        @rejected_ids = []
        start_save
      end

      def start_save
        if tracking = TrackingResult.where({:_id => {"$nin" => @rejected_ids}}).first
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
        TrackingResult.destroy_by_id(tracking["_id"])
      end

      def prepare_tracking(tracking)
        status = YAML::load(tracking["tweets"])
        if Finforenet::RedisFilter.push_data("tracking", status.id.to_s)
          dictionary = tracking["dictionary"]
          @start_count_daily_at = Finforenet::Utils::Time.tomorrow(status.created_at)
          check_daily_keyword(status)
          remove_tracking(tracking)
          Finforenet::Jobs::TrackingTweet.new(status,dictionary)
          start_save
        else
          tweet = Secondary::TweetResult.where(:tweet_id => status.id.to_s).first
          if tweet
            @rejected_ids.delete(tracking["_id"]) if tracking["_id"].present?
            remove_tracking(tracking)
          else
            @rejected_ids.push(tracking["_id"])
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
            tracking = TrackingResult.where({"_id" => tracking["_id"]}).first
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

