module Finforenet
	module Workers
		class CountFollower
			attr_accessor :failed_tasks, :log, :limit_date, :error_log

			def initialize(daily_tweet_id="", start_at="", end_at="", keyword_regex="")
				@failed_tasks = []
				@error_log = Logger.new("#{RAILS_ROOT}/log/daily_follower.log")
				if daily_tweet_id.blank? && start_at.blank? && end_at.blank? && keyword_regex.blank?
					start_count_keywords
				else
					start_checking(daily_tweet_id, start_at, end_at, keyword_regex)
				end
			end

			def start_checking(dt_id, start_at, end_at, keyword_title)
				daily_tweet = DailyTweet.find(dt_id)

				if daily_tweet
					options = {:keywords => keyword_title, :created_at => {"$gte" => start_at, "$lt" => end_at}}
					tweets = TweetResult.where(options).only(:keywords,:created_at,:audience)
					total_followers = tweets.inject(0){|sum, t| sum += t.audience.to_i }
					daily_tweet = daily_tweet.update_attribute(:follower,total_followers)            
				end
				rescue => e
					on_failed(e)
			end

			def on_failed(e)
				@error_log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
				@error_log.debug "Date     : #{Time.now}"
				@error_log.debug "Error Msg: " + e.to_s
				@error_log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
			end

			def update_keyword_traffic
				limit_at = DailyTweet.desc(:created_at).first.created_at.utc.midnight
				this_week = limit_at.monday
				time_ranges = [{"$gt" => limit_at.ago(7.days), "$lte" => limit_at}, {"$gt" => limit_at.ago(14.days), "$lte" => limit_at}, {"$gte" => this_week.ago(10.weeks), "$lt" => this_week}]
				traffics = Traffic.all
				traffics.each do |traffic|
					traffic.keyword_traffics.each do |keyword_traffic|
						counter = 0
						time_ranges.each do |time_range|

							options = {:keyword_id => keyword_traffic.keyword_id, :created_at => time_range}
							total = traffic_result(options,traffic.title)

							if counter == 0
								keyword_traffic.update_attribute(:day7, total)
							elsif counter == 1
								keyword_traffic.update_attribute(:day14, total)
							elsif counter == 2
								keyword_traffic.update_attribute(:week10, total)
							end
							counter += 1
						end
					end
				end
				prepare_cache_keywords
			end

			def traffic_result(options,category)
				tweets = DailyTweet.where(options)
				total = 0

				if category.match(/audience|follow/i)
					total = tweets.inject(0){|sum, t| sum += t.follower.to_i }
				elsif category.match(/tweet|total/i)
					total = tweets.inject(0){|sum, t| sum += t.total.to_i }
				end
				return total
			end


				def start_count_keywords
					keywords = Keyword.all.map(&:id)
					#limit_at = DailyTweet.desc(:created_at).first.created_at.utc.midnight
					#start_at = limit_at
					#end_at = start_at.tomorrow
					start_at = "02/01/2012".to_time.utc.midnight
					limit_at = DailyTweet.last.created_at.utc.midnight
					end_at = start_at.tomorrow
					count_keyword_from(keywords,start_at,end_at,limit_at)
					#count_keyword_from(keywords,start_at,end_at,limit_at.tomorrow)
				end

				def count_keyword_from(keywords,start_date,end_date,limit_at)           
					 while start_date < limit_at
						 count_current_day(keywords,start_date,end_date)
						 start_date = end_date
						 end_date = start_date.tomorrow
					 end
					 #update_keyword_traffic
					 resume_failed_task if @failed_tasks.length > 0
				end

				def count_current_day(keywords,start_at,end_at)
					keywords.each do |key|
						begin
							create_or_update_daily_data(key,start_at,end_at)
						rescue => e
							on_failed(e)
							@failed_tasks << {:keyword => key, :start_at => start_at, :end_at => end_at}
							sleep(random_timer)
							next
						end
					end
				end

			 def on_failed(e)
				@log = Logger.new("#{RAILS_ROOT}/log/daily_follower.log")
				@log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
				@log.debug "Date     : #{Time.now}"
				@log.debug "Error Msg: " + e.to_s
				@log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
			 end

				def create_or_update_daily_data(key,start_at,end_at)
					keyword = Keyword.find(key)

					if keyword
						daily_tweet = DailyTweet.where({:created_at => start_at, :keyword_id => keyword.id}).first
						dts = DailyTweet.where({:created_at => {"$gte" => start_at, "$lt" => start_at.tomorrow}, :keyword_id => keyword.id})
						if dts.count > 1
							dts.each do |dt|
								dt.destroy if dt.id != daily_tweet.id
							end
						end
						if daily_tweet
							options = {:tweet_text => to_regex(keyword.title), :created_at => {"$gte" => start_at, "$lt" => end_at}}
							tweets = Mongoid.database['tweet_results'].find(options).to_a
							total = tweets.inject(0){|sum, item| sum += item['audience'].to_i }
							daily_tweet.update_attribute(:follower,total)
						end

					end

				end

				def resume_failed_task
					sleep(random_timer)
					new_tasks = @failed_tasks
					@failed_tasks = []
					new_tasks.each do |task|
						begin
							create_or_update_daily_data(task[:keyword],task[:start_at],task[:end_at])
						rescue => e
							on_failed(e)
							@failed_tasks << {:keyword => task[:keyword], :start_at => task[:start_at], :end_at => task[:end_at]}
							sleep(random_timer)
							next
						end
					end
					resume_failed_task if @failed_tasks.length > 0
				end

				def random_timer
					return rand(10) + 5
				end


			 def scan_text(text)
				 text.scan(/#{@dictionaries}/i)
			 end

			 def to_regex(str)
				 array_keywords = str.split(",")
				 str = array_keywords.map{|a|
								if !a.include?("$")
									"[^$]#{a}|^#{a}|[^$]#{a}$"
								else
									k = a.gsub("$","[$]")
								 "#{k}\s|#{k}$"
								end
							}.join("|").gsub(/\'|\"/i,"")
					return Regexp.new(str, Regexp::IGNORECASE)
			 end


		end
	end
end
