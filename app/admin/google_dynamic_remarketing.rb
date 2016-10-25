ActiveAdmin.register_page 'Google Dynamic Remarketing' do
  menu parent: 'Other', priority: 80

  content title: 'Google Dynamic Remarketing' do
    file_path = Rightboat::GoogleDynamicRemarketing.csv_fullpath

    if File.exist?(file_path)
      para { link_to 'CSV feed', Rightboat::GoogleDynamicRemarketing.csv_path, target: '_blank' }
      para { "Last updated: <b>#{File.mtime(file_path)}</b>".html_safe }
    end
    para {
      link_to 'Generate', {action: :generate_csv}, method: :post, class: 'button', data: {disable_with: 'Working...'}
    }
  end

  page_action :generate_csv, method: :post do
    Rightboat::GoogleDynamicRemarketing.generate_csv
    redirect_to({action: :index}, notice: 'CSV feed has been generated')
  end

end
