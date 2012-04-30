module ApplicationHelper
  def clean_tag(dirty_tag)
    he = HTMLEntities.new
    return sanitize(he.decode(dirty_tag).gsub('&lt;','<').gsub('&gt;','>'))
  end

  def tweet_language(tweet,member)
    # translator = WhatLanguage.new(:all)
    # lang_text = translator.language(text_without_url(tweet.tweet_text))
    # return (!tweet.lang.blank?) ? tweet.lang : "#{member.lang}, #{lang_text}"
    tweet["lang"] || (member ? member.lang : "")
  end

  def text_without_url(text)
    return text.gsub(/((https?|ftp)\:\/\/([\w-]+\.)?([\w-])+\.(\w)+\/?[\w\?\.\=\&\-\#\+\-\#\+\/]+)/i,'')
  end

  def page_entries_info(collection, options = {})
    collection_name = options[:collection_name] || (collection.empty?? 'entry' : collection.first.class.name.underscore.sub('_', ' '))

    if collection.num_pages < 2
      case collection.size
      when 0; "No #{collection_name.pluralize} found"
      when 1; "Displaying 1 #{collection_name}"
      else;   "Displaying all #{collection.size} #{collection_name.pluralize}"
      end
    else
      %{Displaying %d&nbsp;-&nbsp;%d of %s in total}% [
        collection.offset_value + 1,
        collection.offset_value + collection.length,
        number_with_delimiter(collection.total_count)
      ]
    end
  end

  def display_chart_data(chart_type)
    data = []
    data.push("Average") if chart_type.total_average
    data.push("Tweets") if chart_type.total_tweet
    data.push("Follower") if chart_type.total_follower
    return data.join(", ")
  end

  def display_chart_period(chart_type)
    if !chart_type.days.blank?
      period = "#{chart_type.days} Days"
    elsif !chart_type.weeks.blank?
      period = "#{chart_type.weeks} Weeks"
    else
      period = "#{chart_type.months} Months"
    end
    return period
  end

  def keyword_info_address(keyword)
    return "/info/#{keyword.title.gsub(/\s/,'-')}/#{keyword.id.to_s}"
  end
  
  def tickers_address(category,tickers = nil)
    _return_addr = (!tickers.blank? && tickers < 1) ? "#" : "/tickers/#{category.title.gsub(/\s/,'-')}/#{category.id.to_s}"
    return _return_addr
  end
  
  def traffic_analysis(traffic,limit)
    average = traffic.month6.to_f / limit
    percentage = ((traffic.month1.to_f / average)*100).round(2)
    return percentage
  end
  
  def keyword_indicator(traffic,limit=6)
    percentage = traffic_analysis(traffic,limit)
    _return = arrow_symbol(percentage)
    return {:percentage => percentage.to_i, :symbol => _return}
  end
  
  def arrow_symbol(percentage)
    image_name = percentage > 150 ? "arrow_green_up.png" : "arrow_red_down.png"
    return (percentage >= 75 && percentage <= 150) ? "" : image_tag(image_name,:width=>18,:height=>18, :style=>"float:left;")
  end
  
  def index_symbol(options)
    if options[:alert].blank? || options[:alert].to_s == "NaN"
      options[:alert] = 0
    elsif !options[:alert].to_s.match(/\d/) 
      #&& options[:alert].infinity?
      options[:alert] = 0
    end
    image_name = options[:alert].to_i > 150 ? "arrow_green_up.png" : "arrow_red_down.png"
    options[:symbol] = (options[:alert].to_i >= 75 && options[:alert].to_i <= 150) ? "" : image_tag(image_name,:width=>18,:height=>18, :style=>"float:left;")
    return options
  end

  def negatif_to_positif(number)
     number.to_i < 0 ? -number : number
  end
  
  def slug(str)
    str.gsub(/\W/i,"-")
  end

  def self.prepare_news_letter(reports, keyword_traffics, start_at, end_at)
     volumes_up = [] 
     volumes_down = [] 
     audiences_up = [] 
     audiences_down = []
     @reports = reports
     keyword_traffics.each do |keyword_traffic|
       tweet_health_seven = keyword_traffic.tweet_health_seven_days
       audience_health_fourteen = keyword_traffic.audience_health_fourteen_days

       if tweet_health_seven > 150
         volumes_up.push({:keyword_traffic => keyword_traffic, :healthy => tweet_health_seven})
       elsif tweet_health_seven < 75
         volumes_down.push({:keyword_traffic => keyword_traffic, :healthy => tweet_health_seven})
       end

       if audience_health_fourteen > 150
         audiences_up.push({:keyword_traffic => keyword_traffic, :healthy => audience_health_fourteen})
       elsif audience_health_fourteen < 75
         audiences_down.push({:keyword_traffic => keyword_traffic, :healthy => audience_health_fourteen})
       end
    end
    @reports[0][:keywords] = volumes_up
    @reports[1][:keywords] = audiences_up
    @reports[2][:keywords] = volumes_down
    @reports[3][:keywords] = audiences_down
    return @reports
  end
  
end
