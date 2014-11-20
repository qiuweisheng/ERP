class SessionsController < ApplicationController
  skip_before_action :need_super_permission
  before_action :need_login, only: [:destroy, :redirect]
  
  def new
  end

  def create
    @user = User.find_by(serial_number: params[:serial_number])
    if @user and @user.authenticate(params[:password])
      if [User::PERM_SUPER, User::PERM_ADMIN].include? @user.permission
        url = user_url @user
      else
        url = recent_records_url
      end
      redirect_to url
      session[:user_id] = @user.id
      session[:permission] = @user.permission
    else
      redirect_to login_url, alert: '帐户或密码不对'
    end
  end

  def destroy
    session[:user_id] = nil
    session[:permission] = nil
    redirect_to login_url
  end
end
