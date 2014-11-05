require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  test "should get new" do
    get :new
    assert_response :success
  end

  test "should login" do
    user = users(:admin)
    post :create, account_id: user.account_id, password: 'secret'
    assert_redirected_to user_url(assigns(:user))
    assert_equal user.id, session[:user_id]
  end

  test "should fail login" do
    user = users(:admin)
    post :create, account_id: user.account_id, password: 'wrong'
    assert_redirected_to login_url
  end

  test "should logout" do
    delete :destroy
    assert_redirected_to login_url
  end

end
