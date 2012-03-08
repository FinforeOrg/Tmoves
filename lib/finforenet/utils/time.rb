module Finforenet
  module Utils
    class Time
      
      def self.midnight(time)
        time.to_time.utc.midnight
      end
      
      def self.tomorrow(time)
        self.midnight(time).tomorrow
      end
    
    end
  end
end
