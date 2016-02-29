ActiveAdmin.register_page 'DB IP' do
  menu parent: 'Other', priority: 70

  content title: 'Fetch IP information from db-ip.com' do
    render partial: 'index'
  end

  sidebar :tools, partial: 'sidebar'

  controller do
    def index
      @ip_info = Rightboat::DbIpApi.addr_info(params[:ip]) if params[:ip].present?
    end
  end

  page_action :key_info, method: :get do
    @key_info = Rightboat::DbIpApi.key_info
  end

end
