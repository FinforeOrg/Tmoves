class KeywordTraffic
  include Mongoid::Document
  field :month1, :type => Integer
  field :month6, :type => Integer
  field :week10, :type => Integer
  field :day14, :type => Integer
  field :day7, :type => Integer

  index :keyword_id
  index :traffic_id

  belongs_to :keyword
  belongs_to :traffic
   
end
