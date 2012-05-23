class DailyKeyword
  include Sidekiq::Worker
  sidekiq_options :retry => false
  
  def perform(timestamp=nil)
    Finforenet::Workers::CountDaily.new(timestamp)
  end
end
