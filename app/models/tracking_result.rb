class TrackingResult
  include Mongoid::Document
  set_database :rawdb
  field :tweets, :type => String
  field :dictionary, :type => String

  #index :tweets
  #index :dictionary, :type => String
  cache
end
