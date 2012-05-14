require 'open-uri'
require 'net/http'

module Finforenet
  module Workers
    class StreamTrack
      attr_accessor :task_id, :stream_account, :log, :stream_task
      attr_accessor :keywords, :dictionary, :tomorrow

      def initialize(stream_task_id)
        @task_id = stream_task_id          
        @log = Logger.new("#{Rails.root}/log/stream.log")
        @tomorrow = Time.now.utc.midnight.tomorrow
        start_scan if is_task_ready?
        rescue => e
          log_accident(e) unless e.to_s.match(/memcache/i)
      end

      def is_task_ready?
        _return = true
        begin
          @stream_task = ScannerTask.find(@task_id)
        rescue
          _return = false
        else
          @stream_account = @stream_task.scanner_account
          @keywords       = @stream_task.keywords
          @dictionary     = @stream_task.keywords_regex
        end
        return _return
      end

      def oauth_login
        twitter_api = TwitterApi.first
        TweetStream.configure do |config|
          config.consumer_key       = twitter_api.consumer_key
          config.consumer_secret    = twitter_api.consumer_secret
          config.oauth_token        = @stream_account.token
          config.oauth_token_secret = @stream_account.secret
          config.auth_method        = :oauth
          config.parser             = :yajl
          config.user_agent         = "Mozilla/5.0 (X11; Linux i686; rv:7.0) Gecko/20100101 Firefox/7.0"
        end
      end

      def basic_login
        TweetStream.configure do |config|
          config.username    = @stream_account.username
          config.password    = @stream_account.password
          config.auth_method = :basic
          config.parser      = :yajl
        end
      end

      def start_scan
        if @stream_account.token.present?
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
          tracking_result = TrackingResult.create_status(status, @dictionary)
        rescue => e
          log_tweet_error(e.to_s)
        else
          if tracking_result
            begin
              KeywordsAnalyst.perform_async(tracking_result.keywords_str, tracking_result.created_at.to_i, status.user.followers_count)
            rescue
            else
            end
            if tracking_result.created_at.to_time.utc > @tomorrow
              DailyKeyword.perform_async(@tomorrow.yesterday.to_i)
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

