module Finforenet
  module Jobs
    class ElasticImport

      def initialize
       start_import_index
      end

      def start_import_index
        TweetResult.tire.index.import TweetResult.all
      end
    end
  end
end
