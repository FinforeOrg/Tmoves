require 'open-uri'
require 'net/http'

module Finforenet
  module Workers
    class StreamTrack
      attr_accessor :task_id, :stream_account, :log
      attr_accessor :keywords, :dictionary, :tomorrow

      def initialize(stream_task_id)
        @task_id = stream_task_id          
        @log = Logger.new("#{RAILS_ROOT}/log/stream.log")
        @tomorrow = Time.now.utc.midnight.tomorrow
        prepare_cache_data
        start_scan
        rescue => e
          log_accident(e) unless e.to_s.match(/memcache/i)
      end

      def prepare_cache_data
        @stream_account = CACHE.get("account_#{@task_id}")
        @keywords       = CACHE.get("keyword_#{@task_id}")
        @dictionary     = CACHE.get("dictionary_#{@task_id}")
      end

      def oauth_login
        twitter_api = TwitterApi.first
        TweetStream.configure do |config|
          config.consumer_key       = twitter_api.consumer_key
          config.consumer_secret    = twitter_api.consumer_secret
          config.oauth_token        = @stream_account[:token]
          config.oauth_token_secret = @stream_account[:secret]
          config.auth_method        = :oauth
          config.parser             = :yajl
          config.user_agent         = "Mozilla/5.0 (X11; Linux i686; rv:7.0) Gecko/20100101 Firefox/7.0"
        end
      end

      def basic_login
        TweetStream.configure do |config|
          config.username    = @stream_account[:username]
          config.password    = @stream_account[:password]
          config.auth_method = :basic
          config.parser      = :yajl
        end
      end

      def start_scan
        if @stream_account[:token]
          oauth_login
        else
          basic_login
        end

        client = TweetStream::Client.new
        client.on_error do |message|
          log_tweet_error(message)
          sleep(random_timer)
        end.on_delete do |status_id, user_id|
          delete_status(status_id, user_id)
        end.track(*@keywords) do |status,client|
          save_tracking(status)
        end
      end

      def log_accident(e)
          @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
          @log.debug "Date     : #{Time.now}"
          @log.debug "Task ID  : #{@task_id}"
          @log.debug "Error Msg: " + e.to_s
          @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
          h = Net::HTTP.new('tmoves.com')
          h.get("/admin/scanner_tasks/#{@task_id}/restart")
      end
      
      def delete_status(status_id, user_id)
        TrackingResult.delete_status(status_id, user_id)
      end
      
      def save_tracking(status)
        begin
          new_status = TrackingResult.create_status(status, @dictionary)
        rescue => e
          log_tweet_error(e.to_s)
        else
          if new_status.valid?
            Resque.enqueue(Finforenet::Jobs::AnalyzeKeywords, 
                           new_status.keywords_arr.join(","), 
                           status.created_at, 
                           status.user.followers_count)
            if status.created_at.to_datetime.utc > @tomorrow
              Resque.enqueue(Finforenet::Jobs::Bg::DailyKeyword, @tomorrow.yesterday.to_i)
			        @tomorrow = @tomorrow.tomorrow
            end
          end
        end
      end

      def log_tweet_error(message)
          @log.debug "-----------------------------------------------"
          @log.debug "Date : #{Time.now}"
          @log.debug "Task ID : #{@task_id}"
          @log.debug "ERR: #{message}"
          @log.debug "-----------------------------------------------"
      end

      def random_timer
        rand(60)*2
      end
    end
  end
end

