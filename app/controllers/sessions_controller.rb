class SessionsController < ApplicationController
  skip_before_action :need_super_permission
  prepend_before_action :need_login, only: [:destroy, :redirect]
  
  def new
    session[:user_id] = nil
    session[:permission] = nil
  end

  def create
    @user = User.find_by(serial_number: params[:serial_number])
    if @user #and @user.authenticate(params[:password])
      redirect_to_main_page @user
      session[:user_id] = @user.id
      session[:permission] = @user.permission
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
