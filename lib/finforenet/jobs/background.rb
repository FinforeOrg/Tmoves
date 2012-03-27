module Finforenet
  module Jobs
    class Background
      @queue = "StreamTrack"
      
      def self.perform(stream_task_id)
        Finforenet::Workers::StreamTrack.new(stream_task_id)
      end      
    end
  end
end
