class Mining::MigrationTrack
	include Mongoid::Document
	set_database :mining
	field :tweet_id
	index :tweet_id
	
	after_save :check_total
	
	def check_total
		if self.class.count > 50
                  _first = self.class.first
	          _first.delete if _first.present?
		end
	end
	
end
