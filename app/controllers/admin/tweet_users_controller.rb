class Admin::TweetUsersController < ApplicationController

  before_filter :authenticate_admin!

  def destroy
    @tweet_user = TweetUser.find(params[:id])
    @tweet_user.destroy

    respond_to do |format|
      format.html { redirect_to(tweet_results_url) }
      format.xml  { head :ok }
      format.json {render :json => {:status=>"DELETED"}}
    end
  end
end
