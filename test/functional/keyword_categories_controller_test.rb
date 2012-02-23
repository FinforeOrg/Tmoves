require 'test_helper'

class KeywordCategoriesControllerTest < ActionController::TestCase
  setup do
    @keyword_category = keyword_categories(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:keyword_categories)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create keyword_category" do
    assert_difference('KeywordCategory.count') do
      post :create, :keyword_category => @keyword_category.attributes
    end

    assert_redirected_to keyword_category_path(assigns(:keyword_category))
  end

  test "should show keyword_category" do
    get :show, :id => @keyword_category.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @keyword_category.to_param
    assert_response :success
  end

  test "should update keyword_category" do
    put :update, :id => @keyword_category.to_param, :keyword_category => @keyword_category.attributes
    assert_redirected_to keyword_category_path(assigns(:keyword_category))
  end

  test "should destroy keyword_category" do
    assert_difference('KeywordCategory.count', -1) do
      delete :destroy, :id => @keyword_category.to_param
    end

    assert_redirected_to keyword_categories_path
  end
end
