module Finforenet
  module Jobs
    class RepairData
       attr_accessor :failed_tasks, :log, :keywords, :limit_at, :end_at 
       attr_accessor :keyword_counter, :start_at, :tweet_results, :keyword
       attr_accessor :tweet_result, :dictionaries, :daily_tweet

       def initialize
         @failed_tasks = []
         @log = Logger.new("#{RAILS_ROOT}/log/daily_tweet.log")
         @keywords = Mongoid.database["keywords"].find({}).to_a.map{|k| OpenStruct.new k}
         @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
         @log.debug "Date     : #{Time.now}"
         @log.debug "Options  : #{@keywords.size}"
         @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
         @dictionaries = Keyword.all.map(&:title).join(",")
         @dictionaries = to_regex(@dictionaries)
         now = Time.now.utc.midnight
         @start_at = DailyTweet.last.created_at
         @start_at = now.yesterday if now == @start_at.utc.midnight
         @end_at = @start_at.tomorrow
         @limit_at = TweetResult.last.created_at.utc.midnight
         Finforenet::RedisFilter.del_data("tweetidx")        
         start_repairing
       end

       def start_repairing
         #while @limit_at > @end_at
           @keywords.each do |keyword|
             created_opt = {:created_at => {"$gte" => @start_at, "$lt" => @end_at}}
             fields_only = { :fields => { :_id => 1, :tweet_text => 1,  :tweet_id => 1}}
             tweet_results = Mongoid.database["tweet_results"].find(created_opt.merge(:tweet_text => to_regex(keyword.title)),fields_only).to_a
             dt_id = DailyTweet.where(created_opt.merge(:keyword_id => keyword._id)).first.id
             total, follower = 0, 0
            
             unless dt_id
               dt_id = DailyTweet.create({:created_at => @start_at, :total => 0, :follower => 0, :keyword_id => keyword._id}).id
             end
            
             tweet_results.each do |tweet_result|
               tweetresult = TweetResult.where(:_id => tweet_result["_id"]).first
               if Finforenet::RedisFilter.push_data("tweetidx", tweet_result["tweet_id"])
                 tags = scan_text(tweet_result["tweet_text"]).uniq.join(",")
                 tweetresult.update_attribute(:keywords, tags)
                 total += 1
                 follower += tweet_result["audience"].to_i
               else
                 tweetresult.destroy
               end if dt_id.present?
             end
             daily_tweet = DailyTweet.where(:_id => dt_id).first
             daily_tweet.update_attributes({:total => total, :follower => follower}) if daily_tweet
           end

           update_traffic_data(@start_at, @end_at)
           #@start_at = @end_at
           #@end_at = @start_at.tomorrow
           @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
           @log.debug "Date     : #{@start_at}"
           @log.debug "Final Analyst  : #{@end_at}"
           @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
         #end
       end
            
       def scan_text(text)
         text.scan(/#{@dictionaries}/i)   
       end
         
       def to_regex(str)
         array_keywords = str.split(",")
         str = array_keywords.map{|a|
                if !a.include?("$")
                  "[^$]#{a}|^#{a}|[^$]#{a}$"
                else
                  k = a.gsub("$","[$]")
                 "#{k}\s|#{k}$"
                end
              }.join("|").gsub(/\'|\"/i,"")
          return Regexp.new(str, Regexp::IGNORECASE)
       end
      
      def update_traffic_data(start_at, end_at)
        this_week = start_at
        ranges_option = [{:option => {"$gte" => start_at.ago(7.days),   "$lt" => start_at}, :attribute => :day7   },
		                     {:option => {"$gte" => start_at.ago(14.days),  "$lt" => end_at}, :attribute => :day14  },
		                     {:option => {"$gte" => start_at.monday.ago(10.weeks), "$lt" => this_week}, :attribute => :week10 }]
		
        @keywords.each do |keyword|
          ranges_option.each do |range|
            daily_tweets = DailyTweet.where({:created_at => range[:option], :keyword_id => keyword._id})
            keyword = Keyword.where(:_id => keyword._id).first
            keyword.keyword_traffics.each do |kt|
              if kt.traffic.title.match(/tweet/i)
                total = daily_tweets.sum(:total)
              else
                total = daily_tweets.sum(:follower)
              end
              kt.update_attribute(range[:attribute], total)
      	    end
          end
        end
          begin
            email_daily_report(start_at,end_at)
          rescue => e
            @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
            @log.debug "Date     : #{@start_at}"
            @log.debug "Start AT : #{start_at}"
            @log.debug "End AT   : #{end_at}"
            @log.debug "Error MSG: #{e.to_s}"
            @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
          end
      end	
      
      def email_daily_report(start_at,end_at)
        Member.all.each do |user|
          UserMailer.news_letter(user, start_at, end_at).deliver  
        end
        #@start_at = @start_at.tomorrow
        #start_analyst(@start_at, @start_at.tomorrow)
        Resque.redis.del "queue:Savetweetresult"
        Resque.enqueue_in(1.days, Finforenet::Jobs::Bg::RepairDaily)
        #expire_action :controller => :home, :action => :categories_tab
      end
                               
    end
  end
end
