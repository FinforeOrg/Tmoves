require 'test_helper'

class ScannerAccountsControllerTest < ActionController::TestCase
  setup do
    @scanner_account = scanner_accounts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:scanner_accounts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create scanner_account" do
    assert_difference('ScannerAccount.count') do
      post :create, :scanner_account => @scanner_account.attributes
    end

    assert_redirected_to scanner_account_path(assigns(:scanner_account))
  end

  test "should show scanner_account" do
    get :show, :id => @scanner_account.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @scanner_account.to_param
    assert_response :success
  end

  test "should update scanner_account" do
    put :update, :id => @scanner_account.to_param, :scanner_account => @scanner_account.attributes
    assert_redirected_to scanner_account_path(assigns(:scanner_account))
  end

  test "should destroy scanner_account" do
    assert_difference('ScannerAccount.count', -1) do
      delete :destroy, :id => @scanner_account.to_param
    end

    assert_redirected_to scanner_accounts_path
  end
end
