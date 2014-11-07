module UsersHelper
  def select_options_for_permission
    [['超级用户', 0], ['管理员', 1], ['收发部', 2], ['柜台', 3]]
  end
end
