module Finforenet
	module Workers
		class CountMonthly
			 attr_accessor :failed_tasks, :log, :ids, :end_date, :start_date

			 def initialize
				 @failed_tasks = []
				 start_count_keywords
			 end

			 def start_count_keywords
					@ids = Keyword.all.map(&:id)
					@end_date = Time.now.utc.midnight.at_beginning_of_month
					@start_date = @end_date.ago(6.months)
					count_monthly_keywords
					rescue => e
						on_failed(e)
			 end

			 def find_options(start_date,end_date,keyword_id)
				 return {:created_at => {"$gte" => start_date,"$lt" => end_date}, :keyword_id => keyword_id}
			 end

			 def count_monthly_keywords
				 @ids.each do |keyword_id|
		       options_1month = find_options(@end_date.ago(1.months),@end_date,keyword_id)
					 tweets_1month = Mongoid.database['daily_tweets'].find(options_1month).to_a
					 total_1month = tweets_1month.inject(0){|total,tweet| total += tweet["total"].to_i }

					 options_6month = find_options(@start_date,@end_date,keyword_id)
		       tweets_6month = Mongoid.database['daily_tweets'].find(options_6month).to_a
					 total_6month = tweets_6month.inject(0){|total,tweet| total += tweet["total"].to_i }

					 keyword_traffic = KeywordTraffic.where(:keyword_id => keyword_id).first
		       keyword_traffic.update_attributes({:month1 => total_1month, :month6 => total_6month})
	       end
				 next_task = @end_date.next_month.since(1.days)
				 Resque.enqueue_at(next_task, Finforenet::Jobs::Bg::MonthlyKeyword)
			 end

			 def on_failed(e)
				@log = Logger.new("#{RAILS_ROOT}/log/monthly_keyword.log")
				@log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
				@log.debug "Date     : #{Time.now}"
				@log.debug "Error Msg: " + e.to_s
				@log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
			 end
		end
	end
end
