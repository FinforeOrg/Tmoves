class AnalyzeKeywords
	include Sidekiq::Worker
	def perform(keywords_str, created_at, follower)
		Finforenet::Workers::AnalyzeKeywords.new(keywords_str, created_at, follower)
	end
end