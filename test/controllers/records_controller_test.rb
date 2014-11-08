require 'test_helper'

class RecordsControllerTest < ActionController::TestCase
  setup do
    @record = records(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:records)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create record" do
    assert_difference('Record.count') do
      client = employees(:one)
      post :create, record: { client: "#{client.class}::#{client.id}", count: @record.count, origin_id: @record.origin_id, product_id: @record.product_id, record_type: @record.record_type, user_id: @record.user_id, weight: @record.weight }
    end

    assert_redirected_to record_path(assigns(:record))
  end

  test "should show record" do
    get :show, id: @record
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @record
    assert_response :success
  end

  test "should update record" do
    patch :update, id: @record, record: { client_id: @record.client_id, count: @record.count, origin_id: @record.origin_id, product_id: @record.product_id, record_type: @record.record_type, user_id: @record.user_id, weight: @record.weight }
    assert_redirected_to record_path(assigns(:record))
  end

  test "should destroy record" do
    assert_difference('Record.count', -1) do
      delete :destroy, id: @record
    end

    assert_redirected_to records_path
  end
end
