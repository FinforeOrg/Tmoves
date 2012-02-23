require 'fastercsv'

module Finforenet
  module Jobs
    module Export
      class Track
        attr_accessor :keywords

        def initialize(keywords)
          @keywords = keywords.split(",")
          start_export_csv
        end

        def start_export_csv
          @keywords = Keyword.all.map(&:title)

          end_time = TweetResult.sorted_by({:created_at=>"desc"}).limit(1).first.created_at.midnight
          start_time = TweetResult.sorted_by({:created_at=>"asc"}).limit(1).first.created_at.midnight
          file_name = start_time.strftime('%D_%B_%Y')+"_"+end_time.strftime('%D_%B_%Y')
          file_name = file_name.gsub(/\W/i,"_")+".csv"

             @heads = ['onDate', 'DayName', 'DatabaseTotal', 'RowTotal'] + @keywords

             csv_string = FasterCSV.generate do |csv|
               csv << @heads
               while start_time < end_time

                 has_result = TweetResult.filtered_by({:start_date=>start_time,:end_date=>start_time.tomorrow}).count
                 record = [start_time.to_date, start_time.to_date.strftime('%A'), has_result, 0]

                 @keywords.each do |key|
                   total = TweetResult.filtered_by({:keyword=>key,:start_date=>start_time,:end_date=>start_time.tomorrow}).count
                   record.push(total)
                 end if has_result.to_i > 0                 
                 csv << record
                 start_time = start_time.tomorrow
               end
             end

             #time_int = Time.now.to_i
             filename = "#{RAILS_ROOT}/public/csv/#{file_name}"
             quotes_file = File.open(filename,"a")
             quotes_file.puts csv_string
             quotes_file.close
        end
      end
    end
  end
end
