# Tracking Result is collection database for storing raw tweet data from Twitter Streaming API
# Tracking Result is using database which is different than primary database
# Mongoid.databases['rawdb']['tracking_results']

class TrackingResult
  include Mongoid::Document
  set_database :rawdb
  
  field :tweets, :type => String
  field :dictionary, :type => String

  #index :tweets
  #index :dictionary, :type => String
  cache
  
  def self.collections_by(options)
    self.where(options)
  end
  
  def self.destroy_by_id(tracking_id)
    _tracking = self.where("_id" => tracking_id).first
    _tracking.destroy if _tracking
  end
  
end
