class SessionsController < ApplicationController
  skip_before_action :store_location
  skip_before_action :need_super_permission

  def new

  end

  def create
    @user = User.find_by(serial_number: params[:serial_number])
    if @user and @user.authenticate(params[:password])
      if @user.permission > 1
        default_url = recent_records_url
      else
        default_url = user_url @user
      end
      redirect_to back_location(default_url)
      session[:user_id] = @user.id
      session[:permission] = @user.permission
    else
      redirect_to login_url, alert: '帐户或密码不对'
    end
  end

  def destroy
    session[:user_id] = nil
    session[:permission] = nil
    session[:current_location] = session[:previous_location] = nil
    redirect_to login_url
  end

  def redirect

  end
end
