Streaming::Application.config.middleware.use ExceptionNotifier,
:email_prefix => "[stream.finfore.net] ",
:sender_address => '"Tmoves" <info@stream.finfore.net>',
:exception_recipients => ['yacobus.reinhart@gmail.com']
