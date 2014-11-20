class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :need_super_permission

  protected
    def authorize(permission: User::PERM_SUPER, only_check_login: false)
      user = User.find_by(id: session[:user_id])
      unless user
        # User not login
        redirect_to login_url
        return
      end

      unless only_check_login
        unless permission.is_a?(Integer)
          permission = User::PERM_SUPER
        end
        unless user.permission <= permission
          if [User::PERM_SUPER, User::PERM_ADMIN].include? user.permission
            url = user_url(user)
          else
            url = recent_records_url
          end
          redirect_to url, notice: '帐户权限不够'
        end
      end
    end
    
    def need_super_permission
      authorize
    end

    def need_admin_permission
      authorize(permission: User::PERM_ADMIN)
    end

    def need_level_2_permission
      authorize(permission: User::PERM_LEVEL_ONE)
    end

    def need_level_3_permission
      authorize(permission: User::PERM_LEVEL_TWO)
    end

    def need_login
      authorize(only_check_login: true)
    end
end
