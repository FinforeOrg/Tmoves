module Finforenet
	module Workers
		class AnalyzeKeywords

			attr_accessor 
			
			def initialize(keywords, created_at, audience)
				update_daily_tweet(keywords, created_at, audience)
			end
			
			def update_daily_tweet(keywords, created_at, audience)
				created_at = get_limit_at(created_at)
				keywords.split(",").each do |keyword|
					sanitized_keyword = keyword.gsub(/(^\s+)|(\s+$)/i,"")
					regex_keyword = Finforenet::Utils::String.keyword_regex(sanitized_keyword)
					saved_keyword = Keyword.where({:title => regex_keyword}).first
					DailyTweet.save_total_and_follower(created_at, audience, saved_keyword.id) if saved_keyword
				end
			end
			
			def get_limit_at(datetime)
				Time.at(datetime.to_i).utc.midnight
			end

		end
	end
end
