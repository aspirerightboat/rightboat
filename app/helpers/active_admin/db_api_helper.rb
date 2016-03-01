module ActiveAdmin::DbApiHelper
  def ip_link(ip)
    link_to(ip, [:admin, :db_ip, ip: ip]) if ip.present?
  end
end