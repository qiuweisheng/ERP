class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  prepend_before_action :need_super_permission

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
          redirect_to_main_page user, notice: '帐户权限不够'
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
    
    def is_admin_permission?(permission)
      [User::PERM_SUPER, User::PERM_ADMIN].include? permission
    end
    
    def redirect_to_main_page(user, notice: nil)
      if is_admin_permission? user.permission
        url = user_url user
      else
        url = records_url
      end
      redirect_to url, notice: notice
    end

    def clear_session_data
      session[:user_id] = nil
      session[:permission] = nil
      cookies.delete(:record_filter_from_date)
      cookies.delete(:record_filter_to_date)
      cookies.delete(:record_filter_record_type)
      cookies.delete(:record_filter_user_id)
      cookies.delete(:record_filter_product_id)
      cookies.delete(:record_filter_employee_id)
      cookies.delete(:record_filter_client_id)
      cookies.delete(:record_filter_particpant_type_id)
      cookies.delete(:record_filter_order_number)
    end
end
