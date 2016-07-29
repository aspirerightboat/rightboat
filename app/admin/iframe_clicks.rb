ActiveAdmin.register IframeClick do

  menu parent: 'Other', label: 'Iframe Clicks'

  config.sort_order = 'id_desc'

  filter :broker_iframe_user_id, as: :select, collection: User.companies
  filter :month, as: :select, collection: (1..12)
  preserve_default_filters!

  actions :all, except: [:new]

  index do
    column :id
    column :broker do |ic|
      user = ic&.broker_iframe&.user
      link_to_if user, user.name, admin_user_path(user)
    end
    column :iframe do |ic|
      iframe = ic&.broker_iframe
      link_to_if iframe, iframe.token, admin_broker_iframe_path(iframe)
    end
    column :ip
    column :url
    column :created_at

    actions
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes(broker_iframe: :user)
    end
  end
end
