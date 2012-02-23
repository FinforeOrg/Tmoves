class KeywordChart
  include Mongoid::Document
  field :featured, :type => Boolean
  field :hidden, :type => Boolean

  belongs_to :keyword
  belongs_to :chart_type
end
