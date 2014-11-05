class SessionsController < ApplicationController
  skip_before_action :store_location
  skip_before_action :need_super_permission

  def new
    session[:current_location] = session[:previous_location] = nil
  end

  def create
    @user = User.find_by(account_id: params[:account_id])
    if @user and @user.authenticate(params[:password])
      session[:user_id] = @user.id
      redirect_to back_location(user_url(@user))
    else
      redirect_to login_url, alert: '帐户或密码不对'
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_url
  end
end
