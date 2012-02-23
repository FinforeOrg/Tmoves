class TrackingResult
  include Mongoid::Document
  field :tweets, :type => String
  field :dictionary, :type => String

  #index :tweets
  #index :dictionary, :type => String
  cache
end
