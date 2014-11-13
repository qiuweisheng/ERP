class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  prepend_before_action :store_location
  before_action :need_super_permission

  protected
    def authorize(permission: 0, only_check_login: false)
      user = User.find_by(id: session[:user_id])
      unless user
        redirect_to login_url, notice: '请登录'
        return
      end

      unless only_check_login
        unless permission.is_a?(Integer)
          permission = 0
        end
        unless user.permission <= permission
          redirect_to back_location(login_url), notice: '帐户权限不够'
        end
      end
    end

    def need_super_permission
      authorize
    end

    def need_admin_permission
      authorize(permission: 1)
    end

    def need_level_2_permission
      authorize(permission: 2)
    end

    def need_level_3_permission
      authorize(permission: 3)
    end

    def need_login
      authorize(only_check_login: true)
    end

    # Record last two location
    def store_location
      # User may access the same url multiple times.
      # We just record the first url once in that case.
      # This guarantee that the recorded urls are different.
      unless session[:current_location] == request.url
        session[:previous_location] = session[:current_location]
        session[:current_location] = request.url
      end
    end

    # Return the previous location if it exist, otherwise return default
    def back_location(default)
      # It is no point to redirect to the current location. So we prevent that case.
      location = session[:current_location] == request.url ? session[:previous_location] : session[:current_location]
      location || default
    end
end
