class TrackingUser
  include Mongoid::Document

	field :description,       :type => String
	field :followers_count,   :type => Integer
	field :statuses_count,    :type => Integer
	field :url,               :type => String
	field :location,          :type => String
	field :friends_count,     :type => Integer
	field :favourites_count,  :type => Integer
	field :time_zone,         :type => String
	field :is_protected,      :type => Boolean
	field :profile_image_url, :type => String
	field :screen_name,       :type => String
	field :lang,              :type => String
	field :name,              :type => String
	field :notifications,     :type => String
	field :twitter_id,        :type => String
	field :joined_at,         :type => Time
	field :listed_count,      :type => Integer

	index :screen_name
	index :joined_at
	index :twitter_id
	
	embedded_in :tracking_result
	
end
