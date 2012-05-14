module Finforenet
	module Jobs
		class AnalyzeKeywords
			@queue = "AnalyzeKeywords"

			def self.perform(keywords, created_at, audience)
				Finforenet::Workers::AnalyzeKeywords.new(keywords, created_at, audience)
			end

		end
	end
end
