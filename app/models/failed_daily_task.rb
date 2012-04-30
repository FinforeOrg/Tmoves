class FailedDailyTask
	include Mongoid::Document
	field :start_at,          :type => Time
	field :end_at,            :type => Time
	field :task_function,     :type => String
	field :error_message,     :type => String
	field :keyword_traffic_id
	field :keyword_id
	
	index :keyword_traffic_id
	index :start_at
	index :task_function
end