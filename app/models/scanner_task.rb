class ScannerTask
  include Mongoid::Document
  include Mongoid::Timestamps

  field :keywords, :type => String
  belongs_to :scanner_account

  validates :keywords, :presence => true, :uniqueness => true

end
