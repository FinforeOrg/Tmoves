    require 'net/http'
    require 'openssl'

    class Net::HTTP   
      alias_method :origConnect, :connect
      def connect
        begin
          @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
        rescue
        end
        origConnect
      end
    end


