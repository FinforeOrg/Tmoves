require 'net/smtp'
module Resque
  module Failure
    # Send an email to the developer, so we know something went foul.
    class Notifier < Base
 
      class << self
        attr_accessor :smtp, :sender, :recipients
      end
 
      def self.configure
        yield self
        Resque::Failure.backend = self unless Resque::Failure.backend == Resque::Failure::Multiple
      end
 
      def save

      message_header =''
      message_header << "From: Finfore Stream<info@finfore.net>\r\n"
      message_header << "To: Yacobus Reinhart<yacobus.reinhart@gmail.com>\r\n"
      message_header << "Subject: #{worker} Is Death\r\n"
      #message_header << "cc: Shane Leonard <shane.a.leonard@gmail.com>\r\n"
      message_header << "Date: " + Time.now.to_s + "\r\n"
      msgstr = message_header + "\r\n
                  Solution: click RETRY link here http://stream.finfore.net:5678/failed\r\n
                  Queue:    #{queue}\r\n
                  Worker:   #{worker}\r\n
                  --------------------------------------------\r\n"

        Net::SMTP.start(self.class.smtp[:address], self.class.smtp[:port], self.class.smtp[:domain],self.class.smtp[:account],self.class.smtp[:password], self.class.smtp[:type]) do |smtp|
          smtp.send_message(msgstr, self.class.sender, self.class.recipients)
        end
        
      rescue
      end
    end
  end
end
