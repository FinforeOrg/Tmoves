class DailyKeyword
  include Sidekiq::Worker
  sidekiq_options :retry => false
  sidekiq_options :queue => :daily_keyword
  
  def perform(timestamp=nil)
    Finforenet::Workers::CountDaily.new(timestamp)
  end
end
