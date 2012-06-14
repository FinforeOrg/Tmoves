class UpdatePrice
   include Sidekiq::Worker
   sidekiq_options :queue => :update_price

   def perform
     dts = DailyTweet.all
     dts.each do |dt|
       dt.update_price
     end
   end
end
