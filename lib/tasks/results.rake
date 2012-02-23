namespace :finfore do

  desc "export tracks results"
  task :track_result_csv  => :environment do
    require 'fastercsv'
    require 'date'

    def start_export_csv
          puts "##############################\n"
          puts "#        TRACKS TO CSV       #\n"
          puts "##############################\n\n"
          puts "[#{Time.now}] Search Keywords ... "
          @keywords = Keyword.all.map(&:title)
          puts " FOUND #{@keywords.size} keywords.\n"
          #start_time = TweetResult.find(:first, :select=>"created_at",:order=>"created_at ASC").created_at.midnight
          #end_time = TweetResult.find(:first, :select=>"created_at",:order=>"created_at DESC").created_at.tomorrow.midnight

       [3,4].each do |x|
          start_time = x.months.ago.midnight
          end_time = start_time.next_month
          file_name = start_time.strftime('%B')+"_"+end_time.strftime('%B')+"_2011.csv"
          
          @heads = ['onDate', 'DayName'] + @keywords

          csv_string = FasterCSV.generate do |csv|
            csv << @heads
            while start_time < end_time
              puts "\n-------------------------------------------- \n"
              puts "[#{Time.now}] Collecting tracks on #{start_time} :\n"
              record = [start_time.to_date, start_time.to_date.strftime('%A')]
              tmp_tracks = []
              default_condition = "created_at >= ? AND created_at < ?"
              conditions = [default_condition, start_time, start_time.tomorrow]
              is_down = TweetResult.count(:all,:select=>"id", :conditions => conditions)
              @keywords.each do |key|
                key_condition = default_condition + " AND keywords LIKE '%#{key}'"
                t1 = Time.now
                total = TweetResult.count(:all,:select=>"created_at,keywords", :conditions => [key_condition, start_time, start_time.tomorrow])
                record.push(total)
                seconds = Time.now - t1
                puts "   => #{key} : #{total} (#{seconds} Sec)\n"
              end if is_down > 0
              csv << record
              start_time = start_time.tomorrow
            end
          end
       
          time_int = Time.now.to_i
          filename = "#{RAILS_ROOT}/public/csv/#{file_name}"
          quotes_file = File.open(filename,"a")
          quotes_file.puts csv_string
          quotes_file.close
          puts "HRRAAYY.... #{file_name}"
      end
    end
              
    start_export_csv

  end
end
              
              
