require 'fastercsv'
class Export
  include Mongoid::Document
  include Mongoid::Timestamps

  field :keywords, :type => String
  field :start_date, :type => Date
  field :end_date, :type => Date
  field :progress_date, :type => Date
  field :total_progress, :type => Integer, :default => 0
  field :percentage, :type => Integer, :default => 1
  field :status, :type => Integer, :default => 0
  field :path, :type => String
  
  attr_accessor :filtered_keywords, :export_data, :export_heads
  belongs_to :user
  
  validates_presence_of :keywords

  cache

  def remove_csv
    path = "#{Rails.root}/public/csv/#{self.id}/"
    begin
      FileUtils.rm_rf(path) if File.directory?(path)
    rescue
    end
  end

  # Status :
  # 0 => new process
  # 1 => on process
  # 2 => failed
  # 3 => resume on process
  # 4 => success

  def set_data(params)
    self.start_date =  params["start_date"]
    self.end_date =  params["end_date"]
    self.keywords = params[:keywords].join(",") unless params[:keywords].nil?
    self.progress_date = self.start_date
    self.percentage = 0
    self.total_progress = 0
    self.status = 0
  end

  def current_status
    case status
    when 0
      "Not start yet"
    when 1
      "On Progress"
    when 2
      "Failed"
    when 3
      "Resume on progress"
    when 4
      "Success"
    end

  end

  # for export data to csv
  def self.export_stream(status)
    before_export status
    unless @export_data.nil?
      begin
        if @export_data.status == 0
          save_to_file(@export_heads.join(",") + "\n")
          @export_data.update_attribute(:path, export_file)
        elsif @export_data.status == 3
          rewrite_csv
        end
        @export_data.update_attribute(:status, 1)

        keyword_ids = []
        #keyword_daily_data = {}

        @filtered_keywords.each do |c|
          keyword = Keyword.where(:title => to_regex(c)).first       
          if keyword
            #keyword_daily_data[keyword.id] = []
            keyword_ids << keyword.id 
          end
        end

       end_date = @export_data.end_date.to_datetime.midnight
       start_date = @export_data.progress_date.to_datetime.midnight
       filter_options = {:created_at => {"$gte" => start_date,"$lt" => end_date}, :keyword_id => {"$in" => keyword_ids}}
       daily_tweets = Mongoid.database['daily_tweets'].find(filter_options).to_a

        FasterCSV.generate do |csv|
          while @export_data.progress_date <= @export_data.end_date
            current_time = @export_data.progress_date.to_datetime.midnight
            record = [current_time, current_time.strftime('%A')]
            current_tweets = daily_tweets.select{|ct| ct if ct["created_at"].midnight == current_time}

            keyword_ids.each do |keyword_id|
              keyword_tweets = current_tweets.select{|dt| dt if dt["keyword_id"] == keyword_id}
              total = keyword_tweets.inject(0){|sum,kt| sum += kt["total"].to_i}
              record.push(total)
              #keyword_daily_data[keyword_id].push({:created_at => current_time, :total => total})
              daily_tweets = daily_tweets - keyword_tweets
            end if current_tweets.length > 0

            #csv << record
            save_to_file(record.join(",") + "\n")
            @export_data.total_progress = count_percentage
            @export_data.percentage = @export_data.percentage + 1
            @export_data.progress_date = @export_data.progress_date.tomorrow
            @export_data.save
          end
        end
        @export_data.update_attributes({:status => 4, :total_progress => 100})
      rescue
        @export_data.update_attribute(:status, 2)
      end
    end
  end

  def self.rewrite_csv
    original_file_path = "#{Rails.root}/public/csv/#{@export_data.id}/#{@export_data.path}"
    original_file = FasterCSV.read(original_file_path)
    if original_file.size > 1
      new_file = FasterCSV.generate do |csv|
        original_file.each_with_index do |x, i|
          csv << x unless i == original_file.size - 1
        end
      end
      new_file_path = "#{Rails.root}/public/csv/#{@export_data.id}/modified_file.csv"
      file = File.open(new_file_path,"a")
      file.puts new_file
      file.close
      FileUtils.mv new_file_path, original_file_path, :force => true
    end
  end
  
  def self.save_to_file(csv_string)
    path = "#{Rails.root}/public/csv/#{@export_data.id}"
    FileUtils.mkdir path unless File.directory?(path)
    filename = "#{path}/#{export_file}"
    quotes_file = File.open(filename,"a+")
    quotes_file.chmod( 0777 )
    quotes_file.puts csv_string
    quotes_file.close
  end
  
  def self.count_percentage()
    100 - (100 - ((@export_data.percentage.to_f / (@export_data.end_date - @export_data.start_date).to_f) * 100)).round
  end
  
  def self.heads_defaults
    ['onDate', 'DayName']
  end
  
  def self.export_file
    @export_data.start_date.strftime('%d_%B_%Y')+"_"+@export_data.end_date.strftime('%d_%B_%Y')+".csv"
  end
  
  def self.before_export(status)
    @export_data = Export.first(:conditions => {:status => status})
    unless @export_data.blank?
      @filtered_keywords = @export_data.keywords.split(",")
      @export_heads = heads_defaults.push(@filtered_keywords).flatten
    end
  end

  def self.to_regex(str)
      array_keywords = str.split(",")
      str = array_keywords.map{|a|
        if !a.include?("$")
         "[^$]#{a}|^#{a}|[^$]#{a}$"
        else
         k = a.gsub("$","[$]")
         "#{k}\s|#{k}$"
        end
      }.join("|").gsub(/\'|\"/i,"")
      return Regexp.new(str, Regexp::IGNORECASE)
    end

end
