require 'yajl'
module Finforenet
	module Workers
		class Savetrack
			attr_accessor :status, :dictionary, :tomorrow
			
			def initialize(status,dictionary,tomorrow)
				@status = tweet_object(decrypt_text(status))
				@dictionary = decrypt_text(dictionary)
				@tomorrow = number_to_time(tomorrow)
				start_save
			end
			
			def decrypt_text(str)
				cipher = Gibberish::AES.new("_!tM0v3s!_")
				cipher.dec(str)
			end
			
			def tweet_object(str)
				parser = Yajl::Parser.new(:symbolize_keys => true)
				parser.parse(str).to_openstruct
			end
			
			def number_to_time(obj)
				Time.at(obj.to_i).utc
			end
			
			def start_save
				tracking_result = TrackingResult.create_status(@status, @dictionary)
				if tracking_result
					keyword, timestamp = tracking_result.keywords_str, tracking_result.created_at.to_i
					KeywordsAnalyst.perform_async(keyword, timestamp, @status.user.followers_count)
					#if tracking_result.created_at.to_time.utc > @tomorrow
					#	DailyKeyword.perform_async(@tomorrow.yesterday.to_i)
					#end
				end
			end
			
		end
	end
end
