module ActiveAdmin::UsersHelper
  def user_admin_link(user)
    link_to user.name, admin_user_path(user)
  end
end