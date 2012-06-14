class UpdatePrice
   include Sidekiq::Worker

   def perform
     dts = DailyTweet.all
     dts.each do |dt|
       dt.update_price
     end
   end
end
