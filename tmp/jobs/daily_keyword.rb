module Finforenet
  module Jobs
    module Bg
      class DailyKeyword
        @queue = "DailyKeyword"

        def self.perform(datetime = nil)
          Finforenet::Workers::CountDaily.new(datetime)
        end

      end
    end
  end
end
