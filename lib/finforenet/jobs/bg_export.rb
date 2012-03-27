module Finforenet
  module Jobs
    module Bg
      class Export
        @queue = "ExportTrackToCSV"

        def self.perform(keywords)
          Finforenet::Workers::ExportTrack.new(keywords)
        end
      end
    end
  end
end