class Admin::StatisticsController < ApplicationController
  layout 'admin'
  before_filter :authenticate_admin!

  def index
  end

  def tracker
    cols = [{:id => 'date',:label => "Date",:type  => "string"},
            {:id => 'number',:label => "Results",:type  => "number"}]
    rows = []

    end_date = Time.now.midnight
    start_date = end_date.ago(2.week)
    daily_tweets = Mongoid.database['daily_tweets'].find({:created_at => {"$gte" => start_date,"$lt" => end_date}}).to_a
    while(start_date < end_date)
      current_tweets = daily_tweets.select{|dt| dt if dt["created_at"].midnight == start_date}
      total = current_tweets.inject(0){|sum,dt| sum += dt["total"].to_i}
      rows << {:c => [{ :v => start_date.strftime('%d/%m/%y') },{:v=>total}]}
      start_date = start_date.tomorrow
      daily_tweets = daily_tweets - current_tweets      
    end

    respond_to do |format|
      format.xml  { render :xml => {:cols=>cols,:rows=>rows} }
      format.json  { render :json => {:cols=>cols,:rows=>rows} }
    end    
  end

  def keywords
    if params[:format] != "html"
     collections = params[:keywords].split(",")
     labels = collections
     labels.push("Average") if collections.length < 2
     columns = [{
            :id    => 'date',
            :label => "Date",
            :type  => "date"
        }] + labels.map do |key|
          {
            :id    => key,
            :label => key,
            :type  => "number"
          }
        end
     rows = []
     keyword_ids = []
     keyword_daily_data = {}
     collections.each do |c|
       keyword = Keyword.where(:title=>to_regex(c)).first       
       if keyword
         keyword_daily_data[keyword.id] = []
         keyword_ids << keyword.id 
       end
     end

     end_date = params[:end_date].to_time.midnight.tomorrow
     start_date = params[:start_date].to_time.midnight
     counter = 0
     filter_options = {:created_at => {"$gte" => start_date,"$lt" => end_date}, :keyword_id => {"$in" => keyword_ids}}
     daily_tweets = Mongoid.database['daily_tweets'].find(filter_options).to_a

    while start_date < end_date
      current_tweets = daily_tweets.select{|ct| ct if ct["created_at"].midnight == start_date}

      if current_tweets.length > 0
         row_data = [{ :v => start_date }]
         keyword_ids.each do |keyword_id|
           keyword_tweets = current_tweets.select{|dt| dt if dt["keyword_id"] == keyword_id}
           total = keyword_tweets.inject(0){|sum,kt| sum += kt["total"].to_i}
           average = 0
           row_data.push({:v => total})

           if counter >= 7 && keyword_ids.length < 2
             average_keywords = keyword_daily_data[keyword_id]
             if average_keywords.length > 0
              average_on_date = average_keywords.select{|ag| ag if ag[:created_at] >= start_date.ago(1.week) && ag[:created_at] <= start_date }
              tota_average_keywords = average_on_date.inject(0){|sum,ad| sum += ad[:total]}
              #average_option = {"$gte" => start_date.ago(1.week),"$lte" => start_date}
              #average_tweets = Mongoid.database['daily_tweets'].find({:created_at => average_option, :keyword_id => {"$in" => keyword_id}}).to_a
              average = tota_average_keywords / 7
             end
             row_data.push({:v => average})
           end

           keyword_daily_data[keyword_id].push({:created_at => start_date, :total => total})
           daily_tweets = daily_tweets - keyword_tweets
         end
         rows.push({:c=>row_data})
       end
       counter += 1
       start_date = start_date.tomorrow
     end

     rows << {:c => [{:v => Date.today}]} if rows.size < 1
    else
      @keywords = params[:keywords]
      @start_date = params[:start_date]
      @end_date = params[:end_date]
      @chart_identification = generate_code
    end
   respond_to do |format|
      format.html {render :layout => false}
      format.xml  { render :xml => {:cols=>columns,:rows=>rows} }
      format.json  { render :json => {:cols=>columns,:rows=>rows} }
   end
  end

end
