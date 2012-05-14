module Finforenet
  module Jobs
    module Bg
   
      class SecondaryDb
        @queue = "SecondaryDb"

        def self.perform
          Finforenet::Jobs::SecondaryMigration.new
        end
      end

    end
  end
end
