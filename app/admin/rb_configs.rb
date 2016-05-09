ActiveAdmin.register RBConfig do
  menu label: 'Settings', priority: 50

  permit_params :key, :value, :kind, :description

  index do
    column :key
    column :value
    column :kind
    column :description
    actions
  end

  sidebar 'Tools', only: [:index] do
    para { link_to 'Reset Max Lead Price - All Brokers', {action: :reset_max_lead_price}, method: :post, class: 'button', data: {disable_with: 'Working...'} }
  end

  collection_action :reset_max_lead_price, method: :post do
    BrokerInfo.where('lead_max_price > ?', RBConfig[:default_max_lead_price]).update_all lead_max_price: RBConfig[:default_max_lead_price]
    redirect_to :back, notice: 'Max lead price reseted successfully.'
  end

end
