require 'test_helper'

class TweetResultsControllerTest < ActionController::TestCase
  setup do
    @tweet_result = tweet_results(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tweet_results)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create tweet_result" do
    assert_difference('TweetResult.count') do
      post :create, :tweet_result => @tweet_result.attributes
    end

    assert_redirected_to tweet_result_path(assigns(:tweet_result))
  end

  test "should show tweet_result" do
    get :show, :id => @tweet_result.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @tweet_result.to_param
    assert_response :success
  end

  test "should update tweet_result" do
    put :update, :id => @tweet_result.to_param, :tweet_result => @tweet_result.attributes
    assert_redirected_to tweet_result_path(assigns(:tweet_result))
  end

  test "should destroy tweet_result" do
    assert_difference('TweetResult.count', -1) do
      delete :destroy, :id => @tweet_result.to_param
    end

    assert_redirected_to tweet_results_path
  end
end
