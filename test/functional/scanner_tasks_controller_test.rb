require 'test_helper'

class ScannerTasksControllerTest < ActionController::TestCase
  setup do
    @scanner_task = scanner_tasks(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:scanner_tasks)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create scanner_task" do
    assert_difference('ScannerTask.count') do
      post :create, :scanner_task => @scanner_task.attributes
    end

    assert_redirected_to scanner_task_path(assigns(:scanner_task))
  end

  test "should show scanner_task" do
    get :show, :id => @scanner_task.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @scanner_task.to_param
    assert_response :success
  end

  test "should update scanner_task" do
    put :update, :id => @scanner_task.to_param, :scanner_task => @scanner_task.attributes
    assert_redirected_to scanner_task_path(assigns(:scanner_task))
  end

  test "should destroy scanner_task" do
    assert_difference('ScannerTask.count', -1) do
      delete :destroy, :id => @scanner_task.to_param
    end

    assert_redirected_to scanner_tasks_path
  end
end
