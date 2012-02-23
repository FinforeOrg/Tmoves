module Finforenet
  module Jobs
      class CountWeekly
       attr_accessor :failed_tasks

       def initialize
         @failed_tasks = []
         start_count_keywords
       end

       def start_count_keywords
          keywords = Keyword.all.map(&:id)
          if WeeklyTweet.count > 0
            last_week = WeeklyTweet.last
            end_monday = last_week.end_at.midnight
            start_monday = last_week.start_at
            count_last_week(keywords,start_monday,end_monday)
          else
            first_tweet = TweetResult.sorted_by({:created_at=>'asc'}).limit(1).first
            start_monday = first_tweet.created_at.monday.midnight
            end_monday = start_monday.next_week
            count_last_week(keywords,start_monday,end_monday)
          end
        end

        def count_last_week(keywords,start_monday,end_monday)
           last_monday = Time.now.monday
           while end_monday <= last_monday
             total_keyword = WeeklyTweet.filtered_by({:start_date=>start_monday,:end_date=>end_monday}).count
             if total_keyword < keywords.length
               count_current_week(keywords,start_monday,end_monday)
             end
             start_monday = end_monday
             end_monday = start_monday.next_week
           end
           resume_failed_task if @failed_tasks.length > 0
        end

        def count_current_week(keywords,start_monday,end_monday)
          keywords.each do |key|
            weekly_tweet = WeeklyTweet.where(:keyword_id => key).and(:start_at=>start_monday).and(:end_at=>end_monday).first
            begin
              create_or_update_weekly_data(key,start_monday,end_monday) unless weekly_tweet
            rescue
              @failed_tasks << {:keyword => key, :start_monday => start_monday, :end_monday => end_monday}
              sleep(random_timer)
              next
            end
          end
        end

        def create_or_update_weekly_data(key,start_monday,end_monday)
          keyword = Keyword.find(key)
          if keyword
            total = TweetResult.filtered_by({:keyword=>keyword.title,:start_date=>start_monday,:end_date=>end_monday}).count
            weekly_tweet = keyword.weekly_tweets.where(:start_at => start_monday).and(:end_at => end_monday).first
            
            if weekly_tweet
              weekly_tweet.update_attribute(:total,total)
            else
              WeeklyTweet.create({:keyword_id => keyword.id, :total=> total,:start_at=>start_monday,:end_at => end_monday})
            end
          end
        end

        def resume_failed_task
          sleep(random_timer)
          new_tasks = @failed_tasks
          @failed_tasks = []
          new_tasks.each do |task|
            begin
              create_or_update_weekly_data(task[:keyword],task[:start_monday],task[:end_monday])
            rescue
              @failed_tasks << {:keyword => task[:keyword], :start_monday => task[:start_monday], :end_monday => task[:end_monday]}
              sleep(random_timer)
              next
            end
          end
          resume_failed_task if @failed_tasks.length > 0
        end
       
        def random_timer
          (rand(60)*2) + 5
        end

    end
  end
end
