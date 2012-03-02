class TweetResult
  include Mongoid::Document
#  include Mongoid::MapReduce
#  include Tire::Model::Search
#  include Tire::Model::Callbacks
#  include Tire::Model::Persistence

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

  #index_name 'tweet_results'
  belongs_to :tweet_user

 # tire do
 #   mapping do
 #    indexes :id, :type => 'string', :index => :not_analyzed
 #    indexes :created_at, :type => 'time'
 #    indexes :tweet_text, :type => 'string'
 #    indexes :tweet_id, :type => 'string'
 #    indexes :keywords, :type => 'string'
 #   end
 # end


  #cache

  def to_indexed_json
    self.to_json(:include => :tweet_user)
  end

  def self.filtered_by options
    return self unless options
    resources = self
    unless options[:keyword].blank?
      array_keywords = options[:keyword].split(",")
      options[:keyword] = array_keywords.map{|a|
        if !a.include?("$")
         "[^$]#{a}|^#{a}|[^$]#{a}$"
        else
         "("+ a.gsub("$","[$]") + "(\W|$))"
        end
      }.join("|").gsub(/\'|\"/i,"")
      regex = Regexp.new(options[:keyword], Regexp::IGNORECASE)
      resources = resources.where(:keywords => regex)
    end

    unless options[:start_date].blank?
      resources = resources.and(:created_at.gte => options[:start_date]) unless options[:keyword].blank?
      resources = resources.where(:created_at.gte => options[:start_date]) if options[:keyword].blank?
    end

    unless options[:end_date].blank?
      resources = resources.and(:created_at.lt => options[:end_date]) unless options[:keyword].blank?
      resources = resources.where(:created_at.lt => options[:end_date]) if options[:keyword].blank?
    end

    if !options[:created_at].blank? && options[:created_at] == 'desc'
     resources = resources.desc(:created_at)
    end

    resources = resources.cache if options[:cache]
    return resources

  end  
  
  def self.keyword_regex(str)
    array_keywords = str.split(",")
    str = array_keywords.map{|a|
            if !a.include?("$")
              "[^$]#{a}|^#{a}|[^$]#{a}$"
            else
              "(" + a.gsub("$","[$]") + "(\W|$))"
            end
          }.join("|").gsub(/\'|\"/i,"")
    return Regexp.new(str, Regexp::IGNORECASE)
  end

  def self.sorted_by options
    if options && options[:created_at] == 'desc'
      self.desc(:created_at)
    else
      self.asc(:created_at)
    end
  end

  def self.sorted_desc
    self.desc
  end

end
