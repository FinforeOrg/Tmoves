module Finforenet
  module Jobs
    module Bg
      class RepairDaily
        @queue = "RepairDaily"

        def self.perform
          Finforenet::Jobs::RepairData.new
        end

      end
    end
  end
end