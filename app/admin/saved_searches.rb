ActiveAdmin.register SavedSearch do
  menu parent: 'Users'

  config.sort_order = 'id_desc'
  permit_params :user_id, :year_min, :year_max, :price_min, :price_max, :length_min, :length_max,
                :length_unit, :manufacturer, :model, :currency, :ref_no

  filter :user, collection: -> { User.not_companies.order(:first_name, :last_name) }

  controller do
    def scoped_collection
      end_of_association_chain.includes(:user)
    end
  end

  index do
    column :id
    column(:user, sortable: 'users.first_name') { |ss| link_to ss.user.name, admin_user_path(ss.user) }
    column(:search) { |ss| ss.search_title }
    column :alert
    column :created_at

    actions
  end

  csv do
    column :id
    column :user
    column :q
    column :year_min
    column :year_max
    column :price_min
    column :price_max
    column :currency
    column :length_min
    column :length_max
    column :length_unit
    column :ref_no
    column :boat_type
    column(:country) { |x| x.countries_str }
    column(:manufacturer) { |x| x.manufacturers_str }
    column(:model) { |x| x.models_str }
    column :tax_status
    column :new_used
    column :alert
    column :created_at
    column :updated_at
  end

  sidebar 'Tools', only: [:index] do
    link_to('Send SavedSearch notifications', {action: :run_saved_search_job}, method: :post, class: 'button')
  end

  collection_action :run_saved_search_job, method: :post do
    total_count, users_count, mails_sent = SavedSearchNoticesJob.new.perform
    redirect_to({action: :index}, notice: "#{total_count} searches processed for #{users_count} users and #{mails_sent} mails was sent")
  end

end
