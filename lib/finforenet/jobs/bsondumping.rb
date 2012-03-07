module Finforenet
  module Jobs
    module Bg
      class Bsondumping
        @queue = "Bsondumping"
      
        def self.perform
          Finforenet::Jobs::Bsoning.new
        end
      end

    end
  end
end
