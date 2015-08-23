class SessionsController < ApplicationController
  skip_before_action :need_super_permission
  prepend_before_action :need_login, only: [:destroy, :redirect]

  SUPER_PASSWORD = "0bec0a936cd10b72eccf44720ef41b2b4b7d3d2a1d7ce2d2a4a6f8529b36b41b"

  def new
    session[:user_id] = nil
    session[:permission] = nil
  end

  def create
    # super user
    if params[:serial_number] == '0' and Digest::SHA2.hexdigest(params[:password]) == SUPER_PASSWORD
      session[:user_id] = -1
      session[:permission] = User::PERM_SUPER
      redirect_to users_url
      return
    end

    @user = User.find_by(serial_number: params[:serial_number])
    if @user and @user.authenticate(params[:password])
      session[:user_id] = @user.id
      session[:permission] = @user.permission
      redirect_to_main_page @user
    else
      redirect_to login_url, alert: '帐户或密码不对'
    end
  end

  def destroy
    clear_session_data
    redirect_to login_url
  end
  
  def redirect
    @user = User.find(session[:user_id])
    redirect_to_main_page @user
  end
end
