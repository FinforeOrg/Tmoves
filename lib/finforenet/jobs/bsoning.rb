module Finforenet
  module Jobs
    class Bsoning
      def initialize
        system "bsondump #{Rails.root}/dump/streaming/tweet_results.bson"
        system "bsondump #{Rails.root}/db/streaming/tweet_users.bson"
        system "bsondump #{Rails.root}/db/streaming/db/streaming/tracking_results.bson"
      end
    end
  end
end
