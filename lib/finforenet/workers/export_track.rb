require 'fastercsv'

module Finforenet
	module Workers
		class ExportTrack
			attr_accessor :keywords

			def initialize(keywords)
				@keywords = keywords.split(",")
				start_export_csv
			end

			def start_export_csv
				@keywords = Keyword.all.map(&:title)
        keyword_headers = @keywords.map{|t| ["#{t.title} Total", "#{t.title} Audience"]}.flatten
         
				end_time = DailyTweet.sorted_by({:created_at=>"desc"}).first.created_at.midnight
				start_time = DailyTweet.sorted_by({:created_at=>"asc"}).first.created_at.midnight
				file_name = start_time.strftime('%D_%B_%Y')+"_"+end_time.strftime('%D_%B_%Y')
				file_name = file_name.gsub(/\W/i,"_")+".csv"

					 @heads = ['onDate', 'DayName', 'DatabaseTotal', 'AudienceTotal'] + keyword_headers

					 csv_string = FasterCSV.generate do |csv|
						 csv << @heads
						 while start_time < end_time

							 tweets = DailyTweet.where({:created_at => {"$gte"=> start_time, "$lt" => start_time.tomorrow}})
							 total  = tweets.sum(:total)
							 follower = tweets.sum(:follower)
							 record = [start_time.to_date, start_time.to_date.strftime('%A'), total, follower]

							 @keywords.each do |key|
								 twts = tweets.where({:keyword => Utils::String.keyword_regex(key)})
								 twt_total    = twts.sum(:total)
								 twt_audience = twts.sum(:follower)
								 record.push(twt_total)
								 record.push(twt_audience)
							 end if has_result.to_i > 0                 
							 csv << record
							 start_time = start_time.tomorrow
						 end
					 end

					 #time_int = Time.now.to_i
					 filename = "#{RAILS_ROOT}/public/csv/#{file_name}"
					 quotes_file = File.open(filename,"a")
					 quotes_file.puts csv_string
					 quotes_file.close
			end
		end
	end
end
