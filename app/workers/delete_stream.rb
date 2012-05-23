class DeleteStream
	include Sidekiq::Worker
	sidekiq_options :retry => false

	def perform(status_id, user_id)
		TrackingResult.delete_status(status_id, user_id)
	end
end
