require 'test_helper'

class TweetUsersControllerTest < ActionController::TestCase
  setup do
    @tweet_user = tweet_users(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tweet_users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create tweet_user" do
    assert_difference('TweetUser.count') do
      post :create, :tweet_user => @tweet_user.attributes
    end

    assert_redirected_to tweet_user_path(assigns(:tweet_user))
  end

  test "should show tweet_user" do
    get :show, :id => @tweet_user.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @tweet_user.to_param
    assert_response :success
  end

  test "should update tweet_user" do
    put :update, :id => @tweet_user.to_param, :tweet_user => @tweet_user.attributes
    assert_redirected_to tweet_user_path(assigns(:tweet_user))
  end

  test "should destroy tweet_user" do
    assert_difference('TweetUser.count', -1) do
      delete :destroy, :id => @tweet_user.to_param
    end

    assert_redirected_to tweet_users_path
  end
end
