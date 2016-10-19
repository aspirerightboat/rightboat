ActiveAdmin.register ImportTrail, as: 'BrokerInventroyTrends' do
  menu parent: 'Boats', priority: 13

  actions :all, except: [:new, :create, :edit, :update, :destroy]

  filter :import_user_id, as: :select, collection: User.companies.order(:company_name), label: 'Broker'
  filter :created_at

  controller do
    private

    def scoped_collection
      end_of_association_chain.includes(import: :user)
    end
  end

  index do
    column :broker do |trail|
      link_to(trail.import.user.name, admin_user_path(trail.import.user)) if trail.import.user
    end
    column :boats_count
    column :new_count
    column :updated_count
    column :deleted_count
    column :not_saved_count
    column :created_at

    actions
  end

  show do
    attributes_table do
      row :broker do |trail|
        link_to(trail.import.user.name, admin_user_path(trail.import.user)) if trail.import.user
      end
      row :boats_count
      row :new_count
      row :updated_count
      row :deleted_count
      row :not_saved_count
      row :created_at
    end
  end

end
