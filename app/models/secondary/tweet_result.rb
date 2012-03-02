class Secondary::TweetResult
  include Mongoid::Document
  set_database :secondary

  field :tweet_id, :type => String
  field :retweet_count, :type => Integer
  field :coordinates, :type => String
  field :geo, :type => String
  field :place, :type => String
  field :source, :type => String
  field :created_at, :type => Time
  field :tweet_text, :type => String
  field :keywords, :type => String
  field :lang, :type => String
  field :audience, :type => Integer

  index :created_at
  index :keywords
  index :tweet_id
  index :tweet_text
  index [[:created_at, Mongo::DESCENDING]]
  shard_key :keywords, :created_at

  belongs_to :tweet_user

  #cache

  def to_indexed_json
    self.to_json(:include => :tweet_user)
  end
  
  def self.StartAt
    "01/01/2012".to_time.utc.midnight
  end
  
  def self.find_or_create(member, status = {}, user_lang = "", exist_keywords = "")
    twt = self.where(:tweet_id => status.id.to_s).first
    return twt if twt
    
    place = status.place.blank? ? "" : status.place.full_name+", "+status.place.country_code
    geo   = status.geo.blank? ? "" : status.geo.coordinates.join(',')
    begin
     lang = TRANSLATOR_GRAM.detect(status.text.gsub(/((https?|ftp)\:\/\/([\w-]+\.)?([\w-])+\.(\w)+\/?[\w\?\.\=\&\-\#\+\-\#\+\/]+)/i,''))
    rescue
     lang = TRANSLATOR.language(status.text.gsub(/((https?|ftp)\:\/\/([\w-]+\.)?([\w-])+\.(\w)+\/?[\w\?\.\=\&\-\#\+\-\#\+\/]+)/i,''))
    end
    obj_data = {:tweet_user_id => member.id,
                :retweet_count => status.retweet_count,
                :coordinates   => status.coordinates,
                :geo           => geo,
                :source        => status.source,
                :place         => place,
                :created_at    => status.created_at.to_datetime,
                :tweet_id      => status.id.to_s,
                :tweet_text    => status.text,
                :lang          => "#{user_lang}, #{lang}",
                :keywords      => exist_keywords.uniq.join(','),
                :audience      => member.followers_count
              }
    self.create(obj_data)
  end

end
