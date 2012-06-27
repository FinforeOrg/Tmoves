module Finforenet
  module Utils
    class String
      def self.keyword_regex(str)
        if !str.include?("$")
      	  _return = '([^$]'+str+'\W)|(^'+str+')|(\W[^$]'+str+'$)'
     	else
      	  k = str.gsub("$","[$]")
          _return = '('+k+'\W)|('+k+'$)'
      	end
        return _return
      end
    end
  end
end
