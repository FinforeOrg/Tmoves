require 'resque/failure/notifier'
require 'resque/failure/multiple'
require 'resque/failure/redis'

Resque::Failure::Multiple.configure do |config|
  config.classes = [Resque::Failure::Redis, Resque::Failure::Notifier]
end

Resque::Failure::Notifier.configure do |config|
  config.smtp = {:address => 'smtp.finfore.net', :port => 587, :domain => 'finfore.net',:account=>'info@finfore.net',:password=>'44London',:type=>:plain, :ssl=>true}
  config.sender = 'info@finfore.net'
  #config.recipients = ['shane.a.leonard@gmail.com', 'yacobus.reinhart@gmail.com']
 config.recipients = ['yacobus.reinhart@gmail.com']
end

