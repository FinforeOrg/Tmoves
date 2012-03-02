class Admin::TweetResultsController < ApplicationController
  layout "admin"
  before_filter :authenticate_admin!
  before_filter :prepare_options

  # HACK INJECTION : Read FootNotes at the bottom.

  def index
    @results = Mongoid.databases["secondary"]["secondary_tweet_results"].find(@options).limit(25).sort([:created_at,-1]).to_a
    respond_to do |format|
      format.html 
      format.xml  { render :xml => @results }
      format.json { render :json => @results }
    end
  end

  def total_records
    count_total_records
  end

  def more_tweets
    prepare_more_tweets
    respond_to do |format|
      format.html { render :layout => false}
      format.xml  { render :xml => @results }
      format.json { render :json => @results }
    end
  end

end

# SPEED-UP VERSION 1.0 on Mongoid-2.2.1:
  # To get fast filter, Mongoid.database injection is better than Model.where or Model.count
  # Ruby Driver has been setup to read from slaves if read_secondary: true in mongoid.yml
  # Pagination is removed, Loading will be slow, i put separated process to get total records,
  #    Kaminari and WillPaginate not really help load performances.
