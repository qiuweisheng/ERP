class SessionsController < ApplicationController
  skip_before_action :store_location
  # skip_before_action :need_super_permission

  def new

  end

  def create
    @user = User.find_by(serial_number: params[:serial_number])
    if @user and @user.authenticate(params[:password])
      redirect_to back_location(user_url(@user))
      session[:user_id] = @user.id
      session[:current_location] = session[:previous_location] = nil
    else
      redirect_to login_url, alert: '帐户或密码不对'
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_url
  end
end
