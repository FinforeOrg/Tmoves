class ApplicationController < ActionController::Base
  protect_from_forgery
  layout :layout_by_resource

  private

  # Overwriting the sign_out redirect path method
   def after_sign_out_path_for(resource_or_scope)
     login_path
   end

   def prepare_chart_header(add_label,start_date,end_date)
    @keyword = Keyword.find(params[:keyword_id])
    labels = [@keyword.title]

    if params[:audience]
      labels = ["Audience","Tweets"]
    else
      labels.push(add_label) unless add_label.blank?
      labels.push("Price")
    end

    @columns = [{ :id => 'string', :label => "Date", :type  => "string" }] + labels.map do |key|
                { :id => key, :label => key, :type  => "number" }
               end
    filter_options = {:created_at => {"$gte" => start_date,"$lt" => end_date}, :keyword_id => @keyword.id}
    @daily_tweets = Mongoid.database['daily_tweets'].find(filter_options).sort([:created_at,1]).to_a
    @rows = []
   end

   def prepare_row_chart(attribute,start_date,current_tweets)
     total = current_tweets.inject(0){|sum,kt| sum += kt[attribute].to_i}
     row_data = [{ :v => start_date.strftime('%d %b %Y') }]
     row_data.push({:v => total})
     if params[:audience]
       tweet_total = current_tweets.inject(0){|sum,kt| sum += kt["total"].to_i}
       row_data.push({:v => tweet_total})
     end
     return row_data
   end

   def push_row_data_chart(current_tweets,row_data)
     @daily_tweets = @daily_tweets - current_tweets
     @rows.push({:c=>row_data})
   end

   def prepare_respond_chart
    @rows << {:c => [{:v => Date.today}]} if @rows.size < 1

    respond_to do |format|
      format.xml  { render :xml => {:cols=>@columns,:rows=>@rows} }
      format.json  { render :json => {:cols=>@columns,:rows=>@rows} }
    end
   end

   def count_total_records
       @total_result = ""
     if params[:search].blank? && params[:kid].blank?
       if @options.present? && @options[:created_at].present?
         timestamp = @options[:created_at]["$gt"] || @options[:created_at]["$lt"]
         if Secondary::TweetResult.StartAt < timestamp
           @total_result = Mongoid.database['tweet_results'].find(@options).count
         else
           @total_result = Secondary::TweetResult.where(@options).count
         end
       else
         @total_result = Mongoid.database['tweet_results'].find(@options).count
         @total_result += Secondary::TweetResult.where(@options).count
       end
       @total_result = DailyTweet.sum(:total)
     else
       if params[:kid].blank?
         keyword = Keyword.where(:title => @options[:tweet_text]).includes([:daily_tweets]).first 
       else
         keyword = Keyword.find(params[:kid])
       end
       
       if keyword
         if params[:month].blank?
           @total_result = keyword.daily_tweets.inject(0){|sum,dt| sum += dt.total.to_i}
         elsif params[:month].to_i == 1
           @total_result = keyword.keyword_traffic.month1.to_i
         elsif params[:month].to_i == 6
           @total_result = keyword.keyword_traffic.month6.to_i
         else
           end_at = Time.now.utc.beginning_of_month.midnight
           start_at = end_at.ago(params[:month].to_i.months)
           filter_options = {:created_at => {"$gte" => start_at,"$lt" => end_at}, :keyword_id => keyword.id}
           daily_tweets = Mongoid.database["daily_tweets"].find(filter_options).to_a
           @total_result = daily_tweets.inject(0){|sum,dt| sum += dt["total"].to_i }
         end
       end
     end
     respond_to do |format|
       format.html { render :text => @total_result }
       format.xml  { render :xml => @total_result }
       format.json { render :json => @total_result }
     end

   end

   def to_regex(str)
      array_keywords = str.split(",")
      str = array_keywords.map{|a|
        if !a.include?("$")
         "[^$]#{a}|^#{a}|[^$]#{a}$"
        else
          ticker = a.gsub("$","[$]")
          "#{ticker}\s|#{ticker}$"
        end
      }.join("|").gsub(/\'|\"/i,"")
      return Regexp.new(str, Regexp::IGNORECASE)
    end

    def prepare_options
      @options = {}      
      @options[:tweet_text] =  to_regex(params[:search]) if !params[:search].blank?
   
      if !params[:keyword_id].blank?
        @keyword = Keyword.find(params[:keyword_id])
        @options[:tweet_text] =  to_regex(@keyword.title)
      end

      if !params[:before_at].blank?
        @options[:created_at] = {"$lt" => params[:before_at].to_time}
      elsif !params[:after_at].blank?
        @options[:created_at] = {"$gt" => params[:after_at].to_time}
      end

    end

    def prepare_more_tweets
      @stamp_status = ''
      @div_tag = params[:pathx]    
      @is_hidden = ""
      @results = []
    
      if !params[:before_at].blank? || !params[:after_at].blank?
        #@results = Mongoid.database['tweet_results'].find(@options,{:sort=>[[:created_at,-1]],:limit=>25}).to_a
        @results = Mongoid.databases["secondary"]["secondary_tweet_results"].find(@options,{:sort=>[[:created_at,-1]],:limit=>25}).to_a
        @results = @results.uniq{ |r| r["tweet_id"] }
      end

      if @results.length > 0
        last_stamp = @results.last['created_at']
        top_stamp = @results.first['created_at']

        if !params[:before_at].blank?
          @stamp_status = "bottomstamp='#{last_stamp}'"
          @stamp_status += " topstamp='#{top_stamp}'" if params[:first_load]
        elsif !params[:after_at].blank?
          @stamp_status = "topstamp='#{top_stamp}'"
          @is_hidden = "display:none;"
        end
      end
    end

    def generate_code
      return (1..6).map{ (0..?z).map(&:chr).grep(/[a-z\d]/i)[rand(62)]}.join
    end
    
    require 'csv'
    def get_tweet_price(query,date_at)
      query = CGI::escape(query.gsub(/\$/,""))
      date_str = CGI::escape(date_at.strftime('%b %d, %Y'))
      url = "http://www.google.com/finance/historical?num=1&output=csv&q=#{query}&enddate=#{date_str}&startdate=#{date_str}"
      begin
       file = open(url)
      rescue
       @cols.pop if !@google_error && @cols
       @google_error = true
       return false
      else
        data = FasterCSV.parse(file, :return_headers=>false).pop
        return data[4]
      end
    end
    
    def get_tweet_prices(query,start_at,end_at)
      query = CGI::escape(query.gsub(/\$/,""))
      start_at = CGI::escape(start_at.strftime('%b %d, %Y'))
      end_at = CGI::escape(end_at.strftime('%b %d, %Y'))
      url = "http://www.google.com/finance/historical?output=csv&q=#{query}&startdate=#{start_at}&enddate=#{end_at}"
      begin
        file = open(url)
      rescue
        @google_error = true
        return []
      else
        prices = CSV.parse(file)
        prices.shift
        return prices
      end
    end
    
    def str_to_date(str,format='%d-%b-%y')
      return Date.strptime(str,format)
    end

  protected

  def layout_by_resource
    if devise_controller?
      "admin"
    else
      "admin"
    end
  end

end
