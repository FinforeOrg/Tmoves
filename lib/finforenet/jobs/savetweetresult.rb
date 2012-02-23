require 'finforenet/jobs/savetrack'
module Finforenet
  module Jobs
   module Bg

    class Savetweetresult
      @queue = "Savetweetresult"

      def self.perform
        Finforenet::Jobs::Savetrack.new
      end

    end

  end
 end
end

