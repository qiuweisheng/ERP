module UsersHelper
  def select_options_for_permission
    User::PERMISSION_TYPES.collect do |i, name|
      [name, i]
    end
  end
  
  def is_admin_permission?(permission)
    [User::PERM_SUPER, User::PERM_ADMIN].include? permission
  end
end
