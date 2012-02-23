require 'test_helper'

class ChartTypesControllerTest < ActionController::TestCase
  setup do
    @chart_type = chart_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:chart_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create chart_type" do
    assert_difference('ChartType.count') do
      post :create, :chart_type => @chart_type.attributes
    end

    assert_redirected_to chart_type_path(assigns(:chart_type))
  end

  test "should show chart_type" do
    get :show, :id => @chart_type.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @chart_type.to_param
    assert_response :success
  end

  test "should update chart_type" do
    put :update, :id => @chart_type.to_param, :chart_type => @chart_type.attributes
    assert_redirected_to chart_type_path(assigns(:chart_type))
  end

  test "should destroy chart_type" do
    assert_difference('ChartType.count', -1) do
      delete :destroy, :id => @chart_type.to_param
    end

    assert_redirected_to chart_types_path
  end
end
