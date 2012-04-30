class UserMailer < ActionMailer::Base
  default :to => "info@tmoves.com"

  def contact_company(option)  
    @name = option[:name]
    @message = option[:message]
    mail(:subject => "[TMoves] #{option[:subject]}", :from => option[:email])  
  end 
  
  def news_letter(user, start_at, end_at)  
    @keyword_traffics = KeywordTraffic.where({:created_at => {"$gte" => start_at, "$lt" => end_at}})
    @user = user
    @start_at = start_at
    @end_at = end_at
    @cache_name = "newsletter_" + @start_at.strftime("%d_%m_%Y") + "_" + @end_at.strftime("%d_%m_%Y")
    @reports = [{:title => "Significant increase in Tweet volume versus the recent activity", :keywords => []},
                {:title => "Significant increase in audience versus recent activity", :keywords => []},
                {:title => "Significant decrease in Tweet volume", :keywords => []},
                {:title => "Significant decrease in audience", :keywords => []}
               ]
    @reports = ApplicationHelper.prepare_news_letter(@reports, @keyword_traffics, @start_at, @end_at)
    report_date = @start_at.strftime("%d-%m-%Y")
    mail(:subject => "Tmoves Daily Report on #{report_date}", :from => "info@tmoves.com", :to => @user.email)  
  end 
  

end
