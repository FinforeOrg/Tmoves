module Finforenet
	module Workers
		class Savetrack
			attr_accessor :task_id, :dictionaries,:log, :failed_count, :start_count_daily_at, :previous_id, :tweet_ids

			def initialize
				@failed_count = 0
				@previous_id = ""
				@log = Logger.new("#{RAILS_ROOT}/log/savetrack.log")
				@log.debug "INITIALIZED    : #{Time.now}"
				start_save
			end

			def start_save
				rejected_ids = Maining::MigrationTrack.all.map{|mt| mt.tweet_id.to_s}
				if tracking = TrackingResult.where(:_id => {"$nin" => rejected_ids}).first
					prepare_tracking(tracking)
				else
					sleep(10)
					start_save
				end

				rescue => e
					problem_occured(e,tracking)
			end

			def check_daily_keyword(status)
				if status.created_at.to_time.utc >= @start_count_daily_at
					Resque.enqueue(Finforenet::Jobs::Bg::DailyKeyword)
				end
			end

			def remove_tracking(tracking)
				tracking.destroy
			end

			def prepare_tracking(tracking)
				status = YAML::load(tracking.tweets)
				if Mining::MigrationTrack.where(:tweet_id => status.id.to_s).count < 1
					Mining::MigrationTrack.create({:tweet_id => status.id.to_s})
					remove_tracking(tracking)
					dictionary = tracking["dictionary"]
					@start_count_daily_at = Finforenet::Utils::Time.tomorrow(status.created_at)
					check_daily_keyword(status)
					Finforenet::Workers::StoreTweet.new(status,dictionary)
					start_save
				else
					if Mining::MigrationTrack.where(:tweet_id => status.id.to_s).count > 0
						remove_tracking(tracking)
					end
					sleep(2)
					start_save
				end
			end

			def problem_occured(e,tracking)
				@log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
				@log.debug "Date     : #{Time.now}"
				@log.debug "Error Msg: " + e.to_s
				@log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
				@failed_count += 1
				if e.to_s.match(/syntax error/i)
					if tracking
						remove_tracking(tracking) if Mining::MigrationTrack.where(:tweet_id => tracking.id.to_s).count > 0
					end
				end
				sleep(20)
				after_failed
			end

			def after_failed
				if @failed_count < 10
					start_save
				else
					Resque.enqueue(Finforenet::Jobs::Bg::Savetweetresult)
				end
			end

		end

	end
end
