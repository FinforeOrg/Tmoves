module Finforenet
  module Jobs
    module Bg
      class Bsondumping
        @queue = "Bsondumping"
      
        def self.perform
          Finforenet::Workers::Bsoning.new
        end
      end

    end
  end
end
