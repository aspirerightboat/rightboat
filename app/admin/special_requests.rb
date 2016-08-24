ActiveAdmin.register SpecialRequest do

  menu parent: 'Users'
  permit_params :user_id, :request_type

  index do
    column(:user, sortable: 'users.first_name') { |ss| link_to ss.user.name, admin_user_path(ss.user) }
    column :request_type

    actions
  end

  filter :user, as: :select, collection: User.companies
  filter :request_type, as: :select, collection: SpecialRequest.request_types.keys

  form do |f|
    f.inputs do
      f.input :user, as: :select, collection: User.companies
      f.input :request_type, as: :select, collection: SpecialRequest.request_types.keys
    end

    f.actions
  end
end
