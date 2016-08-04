ActiveAdmin.register RBConfig do
  menu label: 'Settings', priority: 50

  permit_params :value, :text_value

  index do
    column :key
    column :kind
    column(:value) { |c| truncate(c.value.presence || c.text_value, length: 100) }
    column :description
    actions
  end

  sidebar 'Tools', only: [:index] do
    para { link_to 'Reset Max Lead Price - All Brokers', {action: :reset_max_lead_price}, method: :post, class: 'button', data: {disable_with: 'Working...'} }
  end

  form do |f|
    panel 'Constant fields' do
      attributes_table_for f.object do
        %w(key kind description).each { |column| row column }
      end
    end
    f.inputs do
      if f.object.kind == 'text'
        f.input :text_value
      else
        f.input :value
      end
    end
    actions
  end

  collection_action :reset_max_lead_price, method: :post do
    BrokerInfo.update_all lead_max_price: RBConfig.find_by(key: 'default_max_lead_price').value.to_f
    redirect_to :back, notice: 'Max lead price reseted successfully.'
  end

end
