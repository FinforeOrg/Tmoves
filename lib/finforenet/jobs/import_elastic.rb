module Finforenet
  module Jobs
    module Bg
      class ImportElastic
        @queue = "ImportElastic"

        def self.perform
          Finforenet::Jobs::ElasticImport.new
        end

      end
    end
  end
end
