class TwitterApi
  include Mongoid::Document
  field :consumer_key, :type => String
  field :consumer_secret, :type => String

end
