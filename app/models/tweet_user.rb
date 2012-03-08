class TweetUser
  include Mongoid::Document
  #include Mongoid::Paranoia

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
  
  def self.create_or_update(user)
    member = self.where(:twitter_id => user.id.to_s).first
    member_data = { :description       => user.description,
                    :followers_count   => user.followers_count,
                    :statuses_count    => user.statuses_count,
                    :url               => user.url,
                    :location          => user.location,
                    :friends_count     => user.friends_count,
                    :favourites_count  => user.favourites_count,
                    :is_protected      => user.protected,
                    :profile_image_url => user.profile_image_url,
                    :screen_name       => user.screen_name,
                    :lang              => user.lang,
                    :name              => user.name,
                    :twitter_id        => user.id,
                    :joined_at         => user.created_at.to_datetime,
                    :listed_count      => user.listed_count
                  }
                  
    if member.blank? 
      member = self.create(member_data)
    else
      member.update_attributes(member_data)
    end
    return member
  end

end
