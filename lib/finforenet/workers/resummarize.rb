module Finforenet
  module Workers
    class Resummarize
      attr_accessor :start_date, :end_date, :keywords, :db_type
			
      def initialize(start_at, end_at, db_type = "current")
        @start_date = start_at.to_date
        @end_date = end_at.to_date
        @db_type = db_type
        start_summarize
      end

      def start_summarize
        Finforenet::Utils::Calculation.start_calculate(@start_date, @end_date, "", @db_type)
        rescue => e
          write_error_in_logfile(e)
      end #end_of_start_summarize
 
      def write_error_in_logfile(e)
          @log = Logger.new("#{Rails.root}/log/resummarize.log")
          @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
          @log.debug "Date     : #{Time.now}"
          @log.debug "Error Msg: " + e.to_s
          @log.debug e.backtrace
          @log.debug "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
      end

    end
  end
end
