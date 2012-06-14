module Finforenet
  module Utils
    module Price
 
      def self.check_price(ticker, start_price_date, price = 0)
        while price.to_f <= 0
          price = get_tweet_price(ticker, start_price_date)
          start_price_date = start_price_date.yesterday if price.to_f <= 0
        end
        return price
      end

      require 'csv'
      def self.get_tweet_price(query,date_at)
        query = CGI::escape(query.gsub(/\$/,""))
        date_str = CGI::escape(date_at.strftime('%b %d, %Y'))
        url = "http://www.google.com/finance/historical?num=1&output=csv&q=#{query}&enddate=#{date_str}&startdate=#{date_str}"
        begin
         file = open(url)
        rescue
         @cols.pop if !@google_error && @cols
         @google_error = true
         return nil
        else
          data = CSV.parse(file).pop
          return data[4]
        end
      end

    end
  end
end
