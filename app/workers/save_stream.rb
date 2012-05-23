class SaveStream
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(status,dictionary,tomorrow)
    begin
      tracking_result = TrackingResult.create_status(status, dictionary)
    rescue => e
    else
      if tracking_result
        begin
          KeywordsAnalyst.perform_async(tracking_result.keywords_str, tracking_result.created_at.to_i, status.user.followers_count)
        rescue
          @log = Logger.new("#{Rails.root}/log/stream.log")
          @log.debug "-----------------------------------------------"
          @log.debug "Date : #{Time.now}"
          @log.debug "Task ID : #{dictionary}"
          @log.debug "ERR: #{message}"
          @log.debug "-----------------------------------------------"
        else
          if tracking_result.created_at.to_time.utc > tomorrow
            DailyKeyword.perform_async(tomorrow.yesterday.to_i)
          end
        end
      end
    end
  end
end
