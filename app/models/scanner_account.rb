class ScannerAccount
  include Mongoid::Document
  field :username, :type => String
  field :password, :type => String
  field :is_used, :type => Boolean
  field :token, :type => String
  field :secret, :type => String

  has_many :scanner_tasks
  has_many :twitter_followers
  has_one :scanner_task
end
