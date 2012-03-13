module Finforenet
  module Jobs
    class CountDaily
      attr_accessor :failed_tasks, :log, :keywords, :limit_at, :start_at, :conter

      def initialize(datetime = nil)
       @failed_tasks = []
       @counter = 0
       start_count_keywords(datetime)
      end
	  
      def start_count_keywords(datetime)
        @keywords = Keyword.all.map{|keyword| {:id => keyword.id, :title => keyword.title} }
        @limit_at = Secondary::TweetResult.newest_time
        start_analyst
      end
      
      def start_analyst
        if @counter < @keywords.size
          keyword = @keywords[@counter]
          daily_tweet = DailyTweet.where(:keyword_id => keyword[:id]).desc(:created_at).first
          start_at = daily_tweet.created_at.utc.midnight
          while start_at < @limit_at
            create_daily_tweet(keyword, start_at, start_at.tomorrow)
            start_at = start_at.tomorrow
          end
          @counter += 1
          start_analyst
        else
          check_failed_tasks
        end
      end
        
      def check_daily_tweet(keyword, start_at, end_at)
        daily_tweets = DailyTweet.find_keyword_periode(keyword[:id],start_at,end_at)
        is_exist = false
        total_dt = daily_tweets.count
        
        if total_dt > 1
          daily_tweet = daily_tweets.first
          daily_tweets.map{|dt| dt.delete unless daily_tweet.id == dt.id}
        elsif total_dt > 0 && total_dt < 2
          daily_tweet = daily_tweets.first
        end
        
        if daily_tweet.blank?
          begin
            create_daily_tweet(keyword, start_at, end_at)
          rescue => e
            @failed_tasks.push({:keyword => keyword, :start_at => start_at, :end_at => end_at})
            on_failed(e)
          end
        elsif daily_tweet.total < 1 || daily_tweet.follower < 1
          begin
            dt_info = populate_daily_tweet(keyword,start_at,end_at)
            daily_tweet.update_attributes(dt_info)
          rescue => e
            @failed_tasks.push({:keyword => keyword, :start_at => start_at, :end_at => end_at})
            on_failed(e)
          end
        end
      end
      
      def create_daily_tweet(keyword,start_at,end_at)
        dt_info = populate_daily_tweet(keyword,start_at,end_at)
        dt_opts = {:keyword_id => keyword[:id], 
                   :total      => dt_info[:total], 
                   :follower   => dt_info[:follower], 
                   :created_at => start_at}
        daily_tweet = DailyTweet.create(dt_opts)
      end
      
      def populate_daily_tweet(keyword, start_at, end_at)
        keyword_regex = Finforenet::Utils::String.keyword_regex(keyword[:title])
        options = {:tweet_text => keyword_regex, :created_at => {"$gte" => start_at, "$lt" => end_at}}
			  tweets = Secondary::TweetResult.where(options).to_a
        total = tweets.count
        follower = tweets.sum(&:audience)
        return {:total => total, :follower => follower}
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
        else
          update_traffic_data(@limit_at.yesterday, @limit_at)
        end
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
  	  end if keyword
        end
        email_daily_report
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
