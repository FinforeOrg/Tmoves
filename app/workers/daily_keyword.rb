class DailyKeyword
	include Sidekiq::Worker
	def perform(timestamp)
		Finforenet::Workers::CountDaily.new(timestamp)
	end
end