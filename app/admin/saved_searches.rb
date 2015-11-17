ActiveAdmin.register SavedSearch do
  menu parent: 'Users'

  config.sort_order = 'id_desc'
  permit_params :user_id, :year_min, :year_max, :price_min, :price_max, :length_min, :length_max,
                :length_unit, :manufacturer_model, :currency, :ref_no

  filter :user, collection: -> { User.all }

  controller do
    def scoped_collection
      end_of_association_chain.includes(:user)
    end
  end

  index do
    column(:user) { |ss| link_to ss.user.name, admin_user_path(ss.user) }
    column(:search) { |ss| ss.search_title }
    column :created_at

    actions
  end

  sidebar 'Tools', only: [:index] do
    link_to('Send SavedSearch notifications', {action: :run_saved_search_job}, method: :post, class: 'button')
  end

  collection_action :run_saved_search_job, method: :post do
    total_count, users_count, mails_sent = SavedSearchNoticesJob.new.perform
    redirect_to({action: :index}, notice: "#{total_count} searches processed for #{users_count} users and #{mails_sent} mails was sent")
  end

end
