Streaming::Application.config.middleware.use ExceptionNotification::Rack,
email: {
  :email_prefix => "[stream.finfore.net] ",
  :sender_address => '"Tmoves" <info@stream.finfore.net>',
  :exception_recipients => ['yacobus.reinhart@gmail.com']
}
