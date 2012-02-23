class UserMailer < ActionMailer::Base
  default :to => "info@tmoves.com"

  def contact_company(option)  
    @name = option[:name]
    @message = option[:message]
    mail(:subject => "[TMoves] #{option[:subject]}", :from => option[:email])  
  end 
  
  def news_letter(user, start_at = nil, end_at = nil)  
    @keywords = Keyword.includes(:keyword_traffics).all
    @user = user
    @start_at = start_at.blank? ? Time.now.utc.midnight.yesterday : start_at
    @end_at = end_at.blank? ? @start_at.tomorrow.midnight : end_at
    @cache_name = "newsletter_" + @start_at.strftime("%d_%m_%Y") + "_" + @end_at.strftime("%d_%m_%Y")
    @reports = [{:title => "Significant increase in Tweet volume versus the recent activity", :keywords => []},
                {:title => "Significant increase in audience versus recent activity", :keywords => []},
                {:title => "Significant decrease in Tweet volume", :keywords => []},
                {:title => "Significant decrease in audience", :keywords => []}
               ]
    @reports = ApplicationHelper.prepare_news_letter(@reports, @keywords, @start_at, @end_at)
    mail(:subject => "[TMoves] Daily Report", :from => "info@tmoves.com", :to => @user.email)  
  end 
  

end
