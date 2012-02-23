require 'test_helper'

class KeywordChartsControllerTest < ActionController::TestCase
  setup do
    @keyword_chart = keyword_charts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:keyword_charts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create keyword_chart" do
    assert_difference('KeywordChart.count') do
      post :create, :keyword_chart => @keyword_chart.attributes
    end

    assert_redirected_to keyword_chart_path(assigns(:keyword_chart))
  end

  test "should show keyword_chart" do
    get :show, :id => @keyword_chart.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @keyword_chart.to_param
    assert_response :success
  end

  test "should update keyword_chart" do
    put :update, :id => @keyword_chart.to_param, :keyword_chart => @keyword_chart.attributes
    assert_redirected_to keyword_chart_path(assigns(:keyword_chart))
  end

  test "should destroy keyword_chart" do
    assert_difference('KeywordChart.count', -1) do
      delete :destroy, :id => @keyword_chart.to_param
    end

    assert_redirected_to keyword_charts_path
  end
end
