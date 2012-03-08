module Finforenet
  module Jobs
    class CountDaily
      attr_accessor :failed_tasks, :log, :keywords, :limit_at, :start_at

      def initialize(datetime = nil)
       @failed_tasks = []
       start_count_keywords(datetime)
      end
	  
      def start_count_keywords(datetime)
        @keywords = Keyword.all.map{|keyword| {:id => keyword.id, :title => keyword.title} }
        @limit_at = Secondary::TweetResult.newest_time
        if datetime.present?
          @start_at = datetime.to_time.utc
        else
          @start_at = @limit_at.ago(21.days)
        end
        start_analyst(@start_at, @start_at.tomorrow)
      end
      
      def start_analyst(start_at,end_at)
        if start_at < @limit_at
          @keywords.each do |keyword|
            check_daily_tweet(keyword, start_at, end_at)
          end
          check_failed_tasks
        end
      end
      
      def check_daily_tweet(keyword, start_at, end_at)
        daily_tweets = DailyTweet.where({:created_at => start_at, :keyword_id => keyword[:id]})
        is_exist = false
        
        if daily_tweets.count > 1
          daily_tweets.map{|dt| dt.delete}
        elsif daily_tweets.count == 1
          is_exist = true
        end
        
        unless is_exist
          begin
            create_daily_tweet(keyword, start_at, end_at)
          rescue => e
            @failed_tasks.push({:keyword => keyword, :start_at => start_at, :end_at => end_at})
            on_failed(e)
          end
        end
      end
      
      def check_failed_tasks
        task = @failed_tasks.shift
		    if task
          begin
            check_daily_tweet(task[:keyword], task[:start_at], task[:end_at])
          rescue => e
            @failed_tasks.push(task)
            on_failed(e)
            check_failed_tasks
		      else
			      check_failed_tasks
		      end
        end
        update_traffic_data(@start_at, @start_at.tomorrow)
      end
      
      def create_daily_tweet(keyword,start_at,end_at)
        keyword_regex = TweetResult.keyword_regex(keyword[:title])
        options = {:keywords => keyword_regex, :created_at => {"$gte" => start_at, "$lt" => end_at}}
			  tweets = Mongoid.database['tweet_results'].find(options,{})
        total = tweets.count
        follower = tweets.inject(0){|sum,item| sum += item["audience"].to_i}
        daily_tweet = DailyTweet.create({:keyword_id => keyword[:id], :total=> total, :follower => follower, :created_at => start_at})
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
      
      def update_traffic_data(start_at, end_at)
        this_week = start_at.monday
        ranges_option = [{:option => {"$gte" => start_at.ago(7.days),   "$lt" => start_at}, :attribute => :day7   },
		                     {:option => {"$gte" => start_at.ago(14.days),  "$lt" => @limit_at}, :attribute => :day14  },
		                     {:option => {"$gte" => start_at.ago(10.weeks), "$lt" => this_week}, :attribute => :week10 }]
		
    		@keywords.each do |keyword|
    		  ranges_option.each do |range|
      		  tweets = Mongoid.database['daily_tweets'].find({:created_at => range[:options], :keyword_id => keyword[:id]}).to_a
      			keyword = Keyword.where(:_id => keyword[:id]).first
            keyword.keyword_traffics.each do |kt|
              if kt.traffic.title.match(/tweet/i)
                total = tweets.inject(0){|sum, item| sum =+ item[:total].to_i}
              else
                total = tweets.inject(0){|sum, item| sum =+ item[:follower].to_i}
              end
                kt.update_attribute(range[:attribute], total)
      			end
  		    end
		    end
        email_daily_report
	    end	
      
      def email_daily_report
        Member.all.each do |user|
          UserMailer.news_letter(user).deliver  
        end
        @start_at = @start_at.tomorrow
        start_analyst(@start_at, @start_at.tomorrow)
        #Resque.redis.del "queue:Savetweetresult"
        #Resque.enqueue_in(1.days, Finforenet::Jobs::Bg::DailyKeyword)
        #expire_action :controller => :home, :action => :categories_tab
      end

    end
  end
end
