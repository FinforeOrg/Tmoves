class ShortJob
  include Sidekiq::Worker
  sidekiq_options :retry => false
  sidekiq_options :queue => :short_job

  def perform
     keywords = Keyword.all.map{|x| {:title => x.title, :id => x.id.to_s}}.reverse
 keywords.each do |keyword|
 x = "29/04/2012".to_date
 y = "02/05/2012".to_date
 while x < y
 r = Finforenet::Utils::String.keyword_regex(keyword[:title])
 options = {:created_at => {"$gte" => x, "$lt" => x.tomorrow}}
 results = TrackingResult.where(options.merge(:tweet_text => /#{r}/i))
 total = results.count
 follower = results.sum(:audience)
 dts = DailyTweet.where(options.merge(:keyword_id => keyword[:id]))
 dt = dts.first
 if dts.count > 1
   dts.delete_all
   dt = nil
 end
 if dt
 dt.update_attributes({:total => total.to_i, :follower => follower.to_i})
 else
 DailyTweet.create({:total => total.to_i, :follower => follower.to_i, :keyword_id => keyword[:id], :created_at => x})
 end
 x = x.tomorrow
 end
 end
  end

end
