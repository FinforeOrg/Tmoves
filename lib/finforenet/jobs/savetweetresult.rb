require 'finforenet/jobs/savetrack'
module Finforenet
  module Jobs
   module Bg

    class Savetweetresult
      @queue = "Savetweetresult"

      def self.perform
        Finforenet::Workers::Savetrack.new
      end

    end

  end
 end
end

