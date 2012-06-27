class DailyTweet
  include Mongoid::Document
  #include Mongoid::MapReduce

  field :total,      :type => Integer
  field :created_at, :type => Time
  field :follower,   :type => Integer
  field :price,      :type => Float
  index :created_at
  index [[:created_at, Mongo::DESCENDING]]
  index :keyword_id

  belongs_to :keyword
  before_create :before_creation
  #cache
  
  def self.save_total_and_follower(_created_at, total_follower, _keyword_id)
    midnight = _created_at
    search_options = {:created_at => {"$gte" => midnight, "$lt" => midnight.tomorrow}, 
                      :keyword_id => _keyword_id}
    daily_tweet = self.where(search_options).first
    if daily_tweet
      _total = total_follower.to_i > 0 ? 1 : -1
      daily_tweet.inc(:total, _total)
      daily_tweet.inc(:follower, total_follower)
    else
      daily_tweet = DailyTweet.create({:keyword_id => _keyword_id, 
                         :total      => 1, 
                         :follower   => total_follower, 
                         :created_at => midnight})
    end
    daily_tweet.update_price
    daily_tweet
  end

  def before_creation
    self.update_price if self.valid?
  end

  def update_price
    _keyword = self.keyword
    if _keyword.present? && _keyword.ticker.present? && self.price.blank?
      self.price = Finforenet::Utils::Price.check_price(_keyword.ticker, self.created_at)
      self.save
    end if _keyword.title !~ /EURUSD|GBPUSD|(oil price)|(debt)/i
  end
  
  def self.find_keyword_periode(_keyword_id, start_at, end_at)
    self.where({:created_at => {"$gte" => start_at, "$lt" => end_at}, :keyword_id => _keyword_id})
  end

end
