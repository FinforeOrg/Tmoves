class SaveStream
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(status,dictionary,tomorrow)
    Finforenet::Workers::Savetrack.new(status,dictionary,tomorrow)
  end
end
