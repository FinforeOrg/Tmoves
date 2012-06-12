class TweetDay
	include Mongoid::Document
	field :total,      :type => Integer
	field :created_at, :type => Date
end
