module Finforenet
  module Jobs
    class Background
      @queue = "StreamTrack"
      
      def self.perform(stream_task_id)
        Finforenet::Jobs::Stream::Track.new(stream_task_id)
      end      
    end
  end
end
