class DailyKeyword
	include Sidekiq::Worker
  sidekiq_options :timeout => 3600
	def perform(timestamp=nil)
		Finforenet::Workers::CountDaily.new(timestamp)
	end
end
