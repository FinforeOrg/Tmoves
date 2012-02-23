module Finforenet
  module Jobs
    module Bg
      class DailyKeyword
        @queue = "DailyKeyword"

        def self.perform
          Finforenet::Jobs::CountDaily.new
        end

      end
    end
  end
end
