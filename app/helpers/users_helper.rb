module UsersHelper
  def select_options_for_permission
    User::PERMISSION_TYPES.collect do |i, name|
      [name, i]
    end
  end
end
