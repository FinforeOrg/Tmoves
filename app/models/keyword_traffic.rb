class KeywordTraffic
  include Mongoid::Document
  field :month1, :type => Integer
  field :month6, :type => Integer
  field :week10, :type => Integer
  field :day14, :type => Integer
  field :day7, :type => Integer

  belongs_to :keyword
  belongs_to :traffic
   
end
