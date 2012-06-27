module Finforenet
  module Utils
    module Calculation
      def self.start_calculate(start_date, end_date, key="", db_type = "current")
        @start_date = start_date.to_date
        @db_type = db_type
        @end_date = end_date.to_date
        if key.blank?
          @keywords = Keyword.all.map{|keyword| {:id => keyword.id, :title => keyword.title.to_s} }
        else
          keyword = Keyword.where(:title => key).first
          @keywords = [{:id => keyword.id, :title => keyword.title}]
        end
        _returns = []
        while @start_date < @end_date
          created_at = @start_date.to_time.utc.midnight
          options = {:created_at => {"$gte" => created_at, "$lt" => created_at.tomorrow}}
          @keywords.each do |keyword|
            keyword_regex = Finforenet::Utils::String.keyword_regex(keyword[:title])
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
            if dt.present?
              dt.update_attributes({:total => total, :follower => follower})
            else
              dt = DailyTweet.create({:created_at => @start_date.to_time, :keyword_id => keyword[:id], :total => total.to_i, 
:follower => follower.to_i})
            end
            dt.update_price
            #_returns << {:total => total, :follower => follower, :keyword => keyword[:title], :date => @start_date}
          end
          @start_date = @start_date.tomorrow
        end
        #return _returns
      end
    end
  end
end
