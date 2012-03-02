module Finforenet
  module Jobs
    class SecondaryMigration
      attr_accessor :start_at, :limit_at, :end_at, :log, :failed_task

      def initialize
        @start_at = "01/01/2012".to_time.utc.midnight
        @limit_at = TweetResult.last.created_at.utc.midnight.tomorrow
        @end_at   = @start_at.tomorrow
        @failed_task = {}
        @log = Logger.new("#{Rails.root}/log/secondary_migration.log")
        @log.debug "Started At #{Time.now}"
        start_migration
      end

      def start_migration
        while @start_at < @limit_at
          tweets = Mongoid.database['tweet_results'].find(find_args)
          tweets.each do |tweet|
            store_to_secondary(tweet)
          end
          @start_at = @end_at
          @end_at = @start_at.tomorrow
        end
        @log.debug "Completed At #{Time.now}"       
        rescue => e
          @failed_task = {:start_at => @start_at, :end_at => @end_at, :limit_at => @limit_at}
          problem_occured(e)
      end

      def find_args
        {:created_at => {"$gte" => @start_at, "$lt" => @end_at}}
      end

      def store_to_secondary(tweet)
        migration = Secondary::TweetResult.create({:tweet_user_id => tweet['tweet_user_id'],
                                                   :retweet_count => tweet['retweet_count'],
                                                   :coordinates   => tweet['coordinates'],
                                                   :geo           => tweet['geo'],
                                                   :source        => tweet['source'],
                                                   :place         => tweet['place'],
                                                   :created_at    => tweet['created_at'],
                                                   :tweet_id      => tweet['tweet_id'],
                                                   :tweet_text    => tweet['tweet_text'],
                                                   :lang          => tweet['lang'],
                                                   :keywords      => tweet['keywords'],
                                                   :audience      => tweet['audience']
                                                  })
        tr = TweetResult.where(:_id => tweet['_id']).first
        tr.delete if tr
      end

      def problem_occured(e)
        @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
        @log.debug "Date     : #{@start_at}"
        @log.debug "Error Msg: " + e.to_s
        @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
        if @failed_task.present?
          @start_at = @failed_task[:start_at]
          @end_at = @failed_task[:end_at]
          @limit_at = @failed_task[:limit_at]
          @failed_task = {}
          start_migration
        end
     end 

    end
  end
end
