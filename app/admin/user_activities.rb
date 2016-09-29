ActiveAdmin.register UserActivity do
  menu parent: 'Users'

  config.sort_order = 'id_desc'

  permit_params { UserActivity.column_names - %w(id) }

  filter :kind, as: :select, collection: UserActivity::KINDS
  filter :user_id, as: :numeric, label: 'User ID'
  filter :user_email, as: :string
  filter :boat_id, as: :numeric, label: 'Boat ID'
  filter :lead_id, as: :numeric, label: 'Lead ID'
  filter :created_at

  controller do
    def scoped_collection
      end_of_association_chain.includes(:user, :boat, :lead)
    end
  end

  index do
    id_column
    column :user
    column :user_email
    column :kind
    column :boat
    column :lead
    column :meta_data
    column :created_at

    actions
  end

  form do |f|
    f.inputs do
      f.input :kind
      f.input :user_id, as: :number
      f.input :user_email
      f.input :boat_id, as: :number
      f.input :lead_id, as: :number
    end

    f.actions
  end

end
