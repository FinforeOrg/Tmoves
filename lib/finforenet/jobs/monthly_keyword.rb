module Finforenet
  module Jobs
    module Bg
      class MonthlyKeyword
        @queue = "MonthlyKeyword"

        def self.perform
          Finforenet::Jobs::CountMonthly.new
        end

      end
    end
  end
end
