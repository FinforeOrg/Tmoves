module Finforenet
  module Utils
    class String
      def self.keyword_regex(str)
        if !str.include?("$")
      	  _return = "([^$]#{str}\s)|(^#{str})|(\s[^$]#{str}$)"
      	else
      	  k = str.gsub("$","[$]")
          _return = "(#{k}\s)|(#{k}$)"
      	end
        return _return
      end
    end
  end
end
