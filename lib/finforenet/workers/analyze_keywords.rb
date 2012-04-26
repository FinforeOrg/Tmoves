module Finforenet
	module Workers
		class AnalyzeKeywords

			attr_accessor 
			
			def initialize(keywords, created_at, audience)
				update_daily_tweet(keywords.gsub(/^([^\$|\w]+)|(\s)$/,""), created_at, audience)
			end
			
			def update_daily_tweet(keywords, created_at, audience)
				keywords.split(",").each do |keyword|
					regex_keyword = Finforenet::Utils::String.keyword_regex(keyword.gsub(/(^\s|\s$)/,""))
					saved_keyword = Keyword.where({:title => regex_keyword}).first
					DailyTweet.save_total_and_follower(created_at, audience, saved_keyword.id) if saved_keyword
				end
			end


		end
	end
end
