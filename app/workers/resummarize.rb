class Resummarize
  include Sidekiq::Worker
  sidekiq_options :retry => false
  sidekiq_options :queue => :resummarize
  
  def perform(start_date, end_date)
    Finforenet::Workers::Resummarize.new(start_date, end_date)
  end
end
