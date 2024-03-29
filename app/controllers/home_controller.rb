class HomeController < ApplicationController
  layout 'application'
  before_filter :prepare_options, :only => [:more_tweets, :total_records]
  before_filter :prepare_lastest_traffic, :only => [:follower_weight, :categories_tab, :prices_data, :average_statistic]

  #caches_page :categories_tab, :expires_in => 4.hours
  
  def keywords
	  charts = ["average","audience"]
    random_chart = rand(charts.length)
    random_chart = 0 if random_chart > 1
    @chart_type = charts[random_chart]
    keywords = Keyword.all.cache
    @keyword = keywords[rand(keywords.size-1)]
    #@total = DailyTweet.sum(:total).to_i
	  #keyword_traffic = KeywordTraffic.lastest_info
    #@month1 = keyword_traffic.tweet_one_month
    #@month6 = keyword_traffic.tweet_six_months
  end
  
  def categories_tab      
    @cache_name  = "categories_tab_" + @active_date.strftime("%b_%m_%Y")
    @categories  = KeywordCategory.all.asc(:index_at)
    @keyword_traffics = {}
    KeywordTraffic.since(@active_date.yesterday).map{|kt| @keyword_traffics.merge!({kt.keyword_id.to_s => kt})}
    @statistics  = @categories.map do |category|
      {
        :title    => category.title,
        :keywords => category.ordered_keywords.map{|keyword| @keyword_traffics[keyword.id.to_s]}
      }
    end 
    render :layout => false
  end

  def toc
   respond_to do |format|
      format.html {render :layout => false}
    end
  end

  def info
    unless params[:keyword_id].blank?
      @keyword_traffic = KeywordTraffic.where({:keyword_id => params[:keyword_id]}).desc(:created_at).first
      @active_date = @keyword_traffic.created_at.utc.midnight
      @six_month_percent = @keyword_traffic.tweet_health_six_months
      @seven_days_percent = @keyword_traffic.tweet_health_seven_days
      @audience_fourteen_percent = @keyword_traffic.audience_health_fourteen_days
      @ticker = @keyword_traffic.keyword_str.to_s !~ /GBPUSD|EURUSD|oil/i ? @keyword_traffic.keyword.ticker : nil
      @daily_tweets = DailyTweet.where({:keyword_id => params[:keyword_id], :created_at => {"$gte"=> @active_date.ago(1.year),"$lte" => 
@active_date}}).desc(:created_at)
    end

    respond_to do |format|
      if params[:keyword_id].blank?
        format.html { redirect_to keywords_home_url }
      else
        format.html
      end
    end
  end

  def total_records
    #count_total_records
    if params[:month].present?
      now = Time.now.utc.midnight
      if params[:month].to_i == 1
        end_at = now.beginning_of_month
        start_at = end_at.ago(1.month)
        @total_result = DailyTweet.where({:created_at => {"$gte" => start_at, "$lt" => end_at}}).sum(:total).to_i
      elsif params[:month].to_i == 6
        end_at = now.beginning_of_month
        start_at = end_at.ago(6.months)
        @total_result = DailyTweet.where({:created_at => {"$gte" => start_at, "$lt" => end_at}}).sum(:total).to_i
      end
    else
      $redis.set "total_db", DailyTweet.sum(:total).to_i if $redis.get("total_db").to_i < 1
      @total_result = $redis.get("total_db").to_i
    end
    respond_to do |format|
      format.html { render :text => @total_result }
      format.xml  { render :xml => @total_result }
      format.json { render :json => @total_result }
    end
  end
  
  def prices_data
    @cols = [{:id => 'string',:label => "Periode",:type  => "string"},
             {:id => 'number',:label => "Price (US$)",:type  => "number"}]
    end_date = @active_date
    start_date = end_date.ago(2.weeks)
    @keyword = Keyword.find(params[:keyword_id])
    dts = DailyTweet.where({:keyword_id => params[:keyword_id], :created_at => {"$gte" => start_date, "$lt" => end_date}}).asc(:created_at)
    @rows = []
    dts.each do |dt|
      @rows.push({:c => [{ :v => dt.created_at.strftime('%d %b %Y') },{ :v => dt.price.to_f }]})
    end

    respond_to do |format|
      format.xml  { render :xml => {:cols=>@cols,:rows=>@rows} }
      format.json  { render :json => {:cols=>@cols,:rows=>@rows}}
    end
  end

  def statistics
    @keywords = []
    
    if params[:tickers].blank?
      @cols = [{:id => 'date',  :label => "Periode",:type  => "string"},
               {:id => 'number',:label => "Tweets", :type  => "number"},
               {:id => 'number',:label => "Price",  :type  => "number"}]
      keyword = Keyword.where({:_id => params[:keyword_id]}).first
      @keywords.push(keyword) if keyword
    else
      @category = KeywordCategory.find(params[:keyword_id])
      regex = Regexp.new("^[$]", Regexp::IGNORECASE)
      @keywords = @category.keywords.where(:title => regex).or(:ticker.ne => nil).asc(:title)
      @cols = [{:id => 'string',:label => "Tickers",:type  => "string"},
               {:id => 'number',:label => "Tweets",:type  => "number"}]
    end

    @rows = []
    numb = params[:numb].blank? ? (params[:type] == "monthly" ? 6 : 10) : params[:numb].to_i
    @end_date = params[:type] == "monthly" ? Time.now.utc.midnight.at_beginning_of_month : Time.now.utc.midnight.monday
    @start_date = params[:type] == "monthly" ? @end_date.ago(numb.months) : @end_date.ago(numb.weeks)
    @ids = @keywords.map(&:id)
    options = {:created_at => {"$gte" => @start_date,"$lt" => @end_date}, :keyword_id => { "$in" => @ids}}
    @tweets = Mongoid.database['daily_tweets'].find(options).to_a

    if params[:tickers].blank?
      params[:type] == "monthly" ? process_monthly_chart : process_weekly_chart
    else
      @ids.each do |keyword_id|
        current_tweets = @tweets.select{|dt| dt if is_data_on_range(dt,@start_date,@end_date,keyword_id)}
        total = current_tweets.inject(0){|sum,dt| sum += dt["total"].to_i}
        keyword = Keyword.find(keyword_id)
        row = {:c => [{ :v => keyword.title }, {:v => total}]}
        @rows << row
        @tweets = @tweets - current_tweets
      end
    end

    respond_to do |format|
      format.xml  { render :xml => {:cols=>@cols,:rows=>@rows} }
      format.json  { render :json => {:cols=>@cols,:rows=>@rows}}
    end
  end

  def average_statistic
    end_date = @active_date
    start_date = end_date.ago(2.months)
    prepare_chart_header("Average",start_date,end_date)

    keyword_daily_data = []
    counter = 0
    prices = @keyword.is_ticker? ? get_tweet_prices(@keyword.price,start_date,end_date) : nil
    @columns.pop if !prices || @google_error
    prev_price = 0
    while start_date < end_date
       current_tweets = @daily_tweets.select{|ct| ct if ct["created_at"].midnight == start_date}

       if current_tweets.length > 0
         row_data = prepare_row_chart("total",start_date,current_tweets)
         average = 0

         if counter >= 7
           average_on_date = keyword_daily_data.select{|ag| ag if ag[:created_at] >= start_date.ago(1.week) && ag[:created_at] <= start_date }
           tota_average_keywords = average_on_date.inject(0){|sum,ad| sum += ad[:total]}
           average = tota_average_keywords / 7
           average = tota_average_keywords / 7
           row_data.push({:v => average})
         end

         if prices
           gf = prices.select{|p| p if str_to_date(p[0]) == start_date.to_date}.first
           if gf
             prev_price = gf[4].to_f
             prices.delete(gf[0])
           end
           row_data.push({:v => prev_price})
         end

         keyword_daily_data.push({:created_at => start_date, :total => row_data[1][:v]})
         push_row_data_chart(current_tweets,row_data)
       end

       counter += 1
       start_date = start_date.tomorrow
    end
    prepare_respond_chart
  end

  def follower_weight
    end_date = @active_date
    start_date = end_date.ago(2.weeks)
    prepare_chart_header("",start_date,end_date)
    attribute = params[:audience] ? "follower" : "total"
    day14 = 0 if !params[:audience]

    while start_date < end_date
       current_tweets = @daily_tweets.select{|ct| ct if ct["created_at"].midnight == start_date}
       if current_tweets.length > 0
         row_data = prepare_row_chart(attribute,start_date,current_tweets)
         push_row_data_chart(current_tweets,row_data)
         #day14 += row_data[2][:v] if params[:audience]
       end
       start_date = start_date.tomorrow
    end
    prepare_respond_chart
  end

  def more_tweets
    if !params[:keyword_id].blank?
      prepare_more_tweets
    else
      @results = []
    end

    respond_to do |format|
      format.html { render :layout => false}
      format.xml  { render :xml => @results }
      format.json { render :json => @results }
    end
  end

  def tickers
    @category = KeywordCategory.find(params[:category_id])
  end

  def show_twitter
    @tweet_user = TweetUser.find(params[:id])

    respond_to do |format|
      format.html {render :layout=>false}
      format.xml  { render :xml => @tweet_user }
      format.json  { render :json => @tweet_user }
    end
  end

  def about_us
  end

  def contact_us
  end

  def term_of_service
  end
  
  def delivery_message
    UserMailer.contact_company(params).deliver  
    respond_to do |format|
      format.html {render :text => ""}
    end
  end

  private
    def is_data_on_range(dt,start_date,end_date,keyword_id)
      is_on_range = (dt["created_at"].midnight >= start_date && dt["created_at"].midnight < end_date) ? true : false
      return dt["keyword_id"] == keyword_id && is_on_range
    end

    def process_monthly_chart
      while(@start_date < @end_date)
        row = {:c => [{ :v => @start_date.strftime('%b, %Y') }]}
	        end_date_at = @start_date.next_month
        @ids.each do |keyword_id|
         current_tweets = @tweets.select{|dt| dt if is_data_on_range(dt,@start_date,end_date_at,keyword_id)}
         total = current_tweets.inject(0){|sum,dt| sum += dt["total"].to_i}
         row[:c].push({:v=>total})

         #if params[:tickers].blank?
           middle_month = @start_date.since((Time.days_in_month(@start_date.month,@start_date.year)/2).days)
           middle_month = middle_month.end_of_week.ago(2.days) if middle_month.strftime('%a').match(/Sun|Sat/i)
           @keyword = Keyword.find(keyword_id)
           dt = DailyTweet.where({:keyword_id => @keyword.id, :created_at => {"$gte" => middle_month, "$lt" => middle_month.tomorrow}}).first
           price = dt.price
           row[:c].push({:v=>price.to_f}) if price
         #end
         @tweets = @tweets - current_tweets
        end

        @rows << row
        @start_date = @start_date.next_month
      end
    end

    def process_weekly_chart
      while(@start_date < @end_date)
        row = {:c => [{ :v => @start_date.strftime('%d %b, %Y') }]}
        end_date_at = @start_date.next_week
        @ids.each do |keyword_id|
          current_tweets = @tweets.select{|dt| dt if is_data_on_range(dt,@start_date,end_date_at,keyword_id) }
          total = current_tweets.inject(0){|sum,dt| sum += dt["total"].to_i}
          row[:c].push({:v=>total})

          #if params[:tickers].blank?
            @keyword = Keyword.find(keyword_id)
            dt = DailyTweet.where({:keyword_id => @keyword.id, :created_at => {"$gte" => @start_date.since(2.days), "$lt" => 
@start_date.since(2.days).tomorrow}}).first
            price = dt.price 
            row[:c].push({:v=>price.to_f}) if price
          #end

          @tweets = @tweets - current_tweets
        end
        @rows << row
        @start_date = @start_date.next_week
      end
    end
    
    def daily_analysis(category)
      day_limit = category.match(/tweet/i) ? 7 : 14
      traffic_keywords = @keyword.keyword_traffics
      traffic_tweet = traffic_keywords.select{|traffic_keyword| traffic_keyword if traffic_keyword.traffic.title.match(/tweet/i)}.first
      traffic_audience = (traffic_keywords - [traffic_tweet]).first
      current_tweet = @keyword.daily_tweets.where(:created_at.lt => Time.now.utc.midnight).order(:created_at,-1).first
      @current_time = current_tweet.created_at
      if category.match(/tweet/i)
       total =  day_limit == 7 ? traffic_tweet.day7 : traffic_tweet.day14
       perday = current_tweet.total 
      else
       total =  day_limit == 7 ? traffic_audience.day7 : traffic_audience.day14
       perday = current_tweet.follower
      end
      
      average = (total.to_f / day_limit).round(0)
      average = 1 if average < 1
      alert = ((perday.to_f / average) * 100).to_f
      periode = current_tweet.created_at.strftime('%b %d, %Y')
      return {:average => average, :alert=> alert, :periode => periode, :total => perday}
    end
    
    def prepare_lastest_traffic
      lastest      = KeywordTraffic.lastest_info
      @active_date = lastest.created_at.utc.midnight.tomorrow
    end
end
