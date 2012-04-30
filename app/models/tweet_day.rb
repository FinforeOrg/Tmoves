class TweetResult
	include Mongoid::Document
	field :total,      :type => Number
	field :created_at, :type => Date
end