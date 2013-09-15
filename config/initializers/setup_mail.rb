ActionMailer::Base.default_url_options[:host] = "tmoves.com"
ActionMailer::Base.smtp_settings = {
  :address => "secure.emailsrvr.com",
  :port => 587,
  :domain => "tmoves.com",
  :authentication => :plain,
  :user_name => "information@tmoves.com",
  :password => "London44~",
  :enable_starttls_auto => true
}
