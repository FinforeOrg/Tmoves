# Tracking Result is collection database for storing raw tweet data from Twitter Streaming API
# Tracking Result is using database which is different than primary database
# Mongoid.databases['rawdb']['tracking_results']

class TrackingResult
  include Mongoid::Document
  set_database :rawdb
  
  field :tweet_id,      :type => String
  field :retweet_count, :type => Integer
  field :coordinates,   :type => String
  field :geo,           :type => String
  field :place,         :type => String
  field :source,        :type => String
  field :created_at,    :type => Time
  field :tweet_text,    :type => String
  field :keywords,      :type => String
  field :lang,          :type => String
  field :audience,      :type => Integer
  field :keywords_array,:type => Array
  field :keywords_str,  :type => String
  
  embeds_one :tracking_user
  accepts_nested_attributes_for :tracking_user
  
  index :tweet_id, :unique => true
  index :created_at
  index([ [:created_at,     Mongo::DESCENDING]], :background => true)
  validates_uniqueness_of :tweet_id
  
  def self.collections_by(options)
    self.where(options)
  end
  
  def self.destroy_by_id(tracking_id)
    _tracking = self.where("_id" => tracking_id).first
    _tracking.destroy if _tracking
  end
  
  def self.create_status(status, dictionary)
    keywords = self.filter_keyword(status,dictionary)
    _tracking = self.tweet_object(status,keywords).merge!({:tracking_user_attributes => self.member_object(status.user)})
    self.create(_tracking)
  end
  
  def self.delete_status(status_id, user_id)
    _result = self.where(:tweet_id => status_id.to_s).first
    _result.delete
  end
  
  private
    def self.status_geo(status)
      if status.geo.present? && status.geo.coordinates.present?
        return status.geo.coordinates.join(',')
      else
        return ""
      end
    end
    
    def self.status_place(status)
      status.place.blank? ? "" : status.place.full_name+", "+status.place.country_code
    end
    
    def self.filter_keyword(status, dictionary)
      status.text.scan(/#{dictionary}/i).uniq.compact!
    end
    
    def self.member_object(user)
      _user = { :description       => user.description,
                :followers_count   => user.followers_count,
                :statuses_count    => user.statuses_count,
                :url               => user.url,
                :location          => user.location,
                :friends_count     => user.friends_count,
                :favourites_count  => user.favourites_count,
                :profile_image_url => user.profile_image_url,
                :screen_name       => user.screen_name,
                :lang              => user.lang,
                :name              => user.name,
                :twitter_id        => user.id,
                :joined_at         => user.created_at.to_datetime,
                :listed_count      => user.listed_count
              }
      return _user
    end
    
    def self.tweet_object(status,keywords)
      _tweet = {:retweet_count => status.retweet_count,
                :coordinates   => status.coordinates,
                :geo           => self.status_geo(status),
                :source        => status.source,
                :place         => self.status_place(status),
                :created_at    => status.created_at.to_datetime,
                :tweet_id      => status.id.to_s,
                :tweet_text    => status.text,
                :lang          => status.user.lang,
                :keywords_arr  => keywords,
                :keywords_str  => keywords.join(",")
                :audience      => status.user.followers_count
              }
      return _tweet
    end
  
end
