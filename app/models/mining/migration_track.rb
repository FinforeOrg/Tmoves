class Mining::MigrationTrack
	include Mongoid::Document
	set_database :mining
	field :tweet_id
	index :tweet_id
	
	after_save :check_total
	
	def check_total
		if self.total > 50
			self.first.delete
		end
	end
	
end