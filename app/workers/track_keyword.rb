class TrackKeyword
	include Sidekiq::Worker
  sidekiq_options :queue => :track_keyword
	def perform(task_id)
		Finforenet::Workers::StreamTrack.new(task_id)
	end
end
