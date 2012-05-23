class TrackKeyword
  include Sidekiq::Worker
  #sidekiq_options :queue => :track_keyword
  sidekiq_options :retry => false

  def perform(task_id)
    Finforenet::Workers::StreamTrack.new(task_id)
  end
end
