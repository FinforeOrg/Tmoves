module Finforenet
  module Jobs
    class TrackingTweet

      def initialize(status,dictionary)
        prepare_member(status,dictionary)
      end
     
      def prepare_member(status,dictionary)
        member = TweetUser.create_or_update(status.user)
        prepare_result(status, member, exist_keywords(status))
      end

      def prepare_result(status, member, keywords)  
        tweet_result = Secondary::TweetResult.find_or_create(member, status, keywords)
        created_at   = tweet_result.created_at        followers    = member.followers_count
        
        keywords.each do |keyword|
          regex_keyword = Finforenet::Utils::String.keyword_regex(keyword)
          saved_keyword = Keyword.where({:title => regex_keyword}).first
          DailyTweet.save_total_and_follower(created_at, followers, saved_keyword.id) if saved_keyword
        end
      end
      
      def exist_keywords(status)
        status.text.scan(/#{dictionary}/i).uniq
      end
      
    end
  end
end