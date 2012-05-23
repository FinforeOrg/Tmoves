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
        @log.debug "#{_return} Task ID  : #{@task_id}"
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

            @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
            @log.debug "Date     : #{Time.now}"
            @log.debug "Task ID  : #{@task_id}"
            @log.debug "Dictionary: #{@dictionary}"
            @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"

        client = TweetStream::Client.new
        client.on_error do |message|
          client.stop
          log_tweet_error(message)
        end.on_delete do |status_id, user_id|
          DeleteStream.perform_async(status_id, user_id)
        end.track(*@keywords) do |status,client|
          save_by_worker(status,client)
        end.on_reconnect do |timeout, retries|
          
        end
      end
      
      def save_by_worker(status,client)
        encoded = Yajl::Encoder.encode(status)
        secure_tweet = protect_text(encoded)
        secure_dictionary = protect_text(@dictionary)
        SaveStream.perform_async(secure_tweet,secure_dictionary,@tomorrow.to_i)
        @tomorrow = @tomorrow.tomorrow if status.created_at.to_datetime > @tomorrow
      rescue => e
        log_accident(e)
      end
      
      def protect_text(str)
        cipher = Gibberish::AES.new("_!tM0v3s!_")
        cipher.enc(str)
      end

      def log_accident(e)
          @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
          @log.debug "Date     : #{Time.now}"
          @log.debug "Task ID  : #{@task_id}"
          @log.debug "Error Msg: " + e.to_s
          @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
          restart_worker
      end

      def restart_worker
         #sleep(random_timer)
         scanner_task = ScannerTask.where({:_id => @task_id}).first
         TrackKeyword.perform_async(@task_id)
         if scanner_task
           accounts = ScannerAccount.where({:is_used => false})
           total_account = accounts.count - 1
           if total_account > 0
             begin
               account = accounts.to_a[rand(total_account)]
             rescue
               TrackKeyword.perform_async(@task_id)
             else
               if account
                 scanner_task.scanner_account.update_attribute(:is_used, false)
                 scanner_task.update_attribute(:scanner_account_id, account.id)
                 account.update_attribute(:is_used, true)
               end
               TrackKeyword.perform_async(@task_id)
             end
           end
         end
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
          restart_worker
      end

      def random_timer
        rand(30)*2
      end
    end
  end
end

