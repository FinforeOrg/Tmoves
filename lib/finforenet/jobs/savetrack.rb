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
        tracking = Mongoid.database['tracking_results'].find_one({"_id" => {"$nin" => @rejected_ids}})
        if tracking
          prepare_tracking(tracking)
        else
          sleep(10)
          start_save
        end
        
        rescue => e
        problem_occured(e,tracking)
      end

      def prepare_tracking(tracking)
        status = YAML::load tracking["tweets"]
        if Finforenet::RedisFilter.push_data("tracking", status.id.to_s)
          dictionary = tracking["dictionary"]
          if @start_count_daily_at.blank?
            @start_count_daily_at = status.created_at.to_time.utc.midnight.tomorrow
          elsif status.created_at.to_time.utc >= @start_count_daily_at
            @start_count_daily_at = status.created_at.to_time.utc.midnight.tomorrow
            Resque.enqueue(Finforenet::Jobs::Bg::DailyKeyword)
          end
          
          Mongoid.database['tracking_results'].remove({"_id" => tracking["_id"]})
          Finforenet::Jobs::TrackingTweet.new(status,dictionary)
          start_save
        else
          tweet = Secondary::TweetResult.where(:tweet_id => status.id.to_s).first
          
          if tweet
            Mongoid.database['tracking_results'].remove({"_id" => tracking["_id"]}) 
            @rejected.delete(tracking["_id"])
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
            tracking = Mongoid.database['tracking_results'].find_one({"_id" => tracking["_id"]})
            Mongoid.database['tracking_results'].remove({"_id" => tracking["_id"]}) if tracking
          end
        end
        sleep(20)
        if @failed_count < 10
          start_save
        else
          Resque.enqueue(Finforenet::Jobs::Bg::Savetweetresult)
        end
      end
      
    end

    class TrackingTweet

      def initialize(status,dictionary)
        prepare_member(status,dictionary)
      end
     
      def prepare_member(status,dictionary)
        exist_keywords = status.text.scan(/#{dictionary}/i)
        user = status.user
        member = TweetUser.create_or_update(user)
            prepare_result(status,member,user,exist_keywords)
       end

       def prepare_result(status,member,user,exist_keywords)  
         track_result = Secondary::TweetResult.find_or_create(member,status)

         created_at = track_result.created_at
           keywords = exist_keywords.uniq
           keywords.each do |keyword|
             regex_keyword = TweetResult.keyword_regex(keyword)
             keyword = Keyword.where({:title => regex_keyword}).first
             if keyword
               daily_tweet = keyword.daily_tweets.where({:created_at => {"$gte" => created_at.utc.midnight, "$lt" => created_at.utc.midnight.tomorrow}}).first
               if daily_tweet
                 daily_tweet.inc(:total, 1)
                 daily_tweet.inc(:follower, member.followers_count.to_i)
               else
                 DailyTweet.create({:keyword_id => keyword.id, 
                                    :total => 1, 
                                    :follower => member.followers_count.to_i, 
                                    :created_at => created_at.utc.midnight})
               end
             end
           end
        end

    end

  end
end

