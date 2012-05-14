class TrackKeyword
	include Sidekiq::Worker
	def perform(task_id)
		Finforenet::Workers::StreamTrack.new(task_id)
	end
end