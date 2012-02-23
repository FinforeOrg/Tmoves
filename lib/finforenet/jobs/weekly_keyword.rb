module Finforenet
  module Jobs
    module Bg
      class WeeklyKeyword
        @queue = "WeeklyKeyword"

        def self.perform
          Finforenet::Jobs::CountWeekly.new
        end
        
      end
    end
  end
end
