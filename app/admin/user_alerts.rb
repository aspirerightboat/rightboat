ActiveAdmin.register UserAlert do
  
  menu parent: 'Users', label: 'Alerts'

  config.sort_order = 'id_desc'
  permit_params :user_id, :favorites, :enquiry, :suggestions, :newsletter

  filter :user, collection: -> { User.order(:first_name, :last_name) }

  controller do
    def scoped_collection
      end_of_association_chain.includes(:user)
    end
  end

  index do
    column :id
    column(:user, sortable: 'users.first_name') { |ss| link_to ss.user.name, admin_user_path(ss.user) }
    column :favorites
    column :enquiry
    column :suggestions
    column :newsletter

    actions
  end
end
