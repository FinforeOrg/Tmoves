module Finforenet
  module Jobs
    module Bg
      class DailyFollower
        @queue = "DailyFollower"

        def self.perform(daily_tweet_id="", start_at="", end_at="", keyword_regex="")
          Finforenet::Workers::CountFollower.new(daily_tweet_id, start_at, end_at, keyword_regex)
        end

      end
    end
  end
end
