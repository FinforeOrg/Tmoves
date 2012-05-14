class TrackKeyword
	include Sidekiq::Worker
  sidekiq_options :timeout => 3600
	def perform(task_id)
		Finforenet::Workers::StreamTrack.new(task_id)
	end
end
