module Finforenet
  module Workers
    class Resummarize
      attr_accessor :start_date, :end_date, :keywords, :db_type
			
      def initialize(start_at, end_at, db_type = "current")
        @start_date = start_at.to_date
        @end_date = end_at.to_date
        @db_type = db_type
        @keywords = Keyword.all.map{|keyword| {:id => keyword.id.to_s, :title => keyword.title.to_s} }
        start_summarize
      end

      def start_summarize
        while @start_date < @end_date
          options = {:created_at => {"$gte" => @start_date, "$lt" => @start_date.tomorrow}}
          @keywords.each do |keyword|
            if @db_type == "current"
              fd = TrackingResult.where(options.merge({:keywords_arr.in => [keyword[:title]]}))
            else
              keyword_regex = Finforenet::Utils::String.keyword_regex(keyword[:title])
              fd = Secondary::TweetResult.where(options.merge({:tweet_text => /#{keyword_regex}/i}))
            end
            total = fd.count
            follower = fd.sum(:audience)
            dt = nil
            dts = DailyTweet.where(options.merge({:keyword_id => keyword[:id]}))
            if dts.count > 1
              dts.delete_all
            else
              dt = dts.first
            end
            if dt
              dt.update_attributes({:total => total, :follower => follower})
            else
              dt = DailyTweet.create({:created_at => @start_date.to_time, 
                                      :keyword_id => BSON::ObjectId(keyword[:id]), 
                                      :total => total.to_i, 
                                      :follower => follower.to_i})
            end
            dt.update_price
            @start_date = @start_date.tomorrow
          end #end_of_keywords
        end #end_of_while
        rescue => e
          write_error_in_logfile(e)
      end #end_of_start_summarize
 
      def write_error_in_logfile(e)
          @log = Logger.new("#{Rails.root}/log/resummarize.log")
          @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
          @log.debug "Date     : #{Time.now}"
          @log.debug "Error Msg: " + e.to_s
          @log.debug e.backtrace
          @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
      end

    end
  end
end
