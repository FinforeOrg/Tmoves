module Finforenet
  module Jobs
    module Bg
      class MonthlyKeyword
        @queue = "MonthlyKeyword"

        def self.perform
          Finforenet::Workers::CountMonthly.new
        end

      end
    end
  end
end
