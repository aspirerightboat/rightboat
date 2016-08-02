ActiveAdmin.register FacebookUserInfo do

  menu parent: 'Users'

  config.sort_order = 'id_desc'

  actions :all, except: [:new]

  index do
    column :id
    column('RB User') { |info| link_to info.user.name, admin_user_path(info.user) }
    column('Image') { |info| link_to image_tag(info.image_url), info.profile_url }
    column :first_name
    column :last_name
    column :name
    column :gender
    column :locale
    column :age_min
    column :age_max
    column :timezone
    column :updated_at
    column :created_at

    actions
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes(:user)
    end
  end
end
