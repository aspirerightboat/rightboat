ActiveAdmin.register SavedSearchesAlert do
  menu parent: 'Mails'

  config.sort_order = 'id_desc'
  permit_params :user_id, :saved_search_ids, :saved_search_infos, :opened_at

  filter :user_first_name_or_user_last_name_or_user_email_or_user_id_cont, as: :string, label: 'User Forename | Surname | Email | ID'
  filter :opened_at
  filter :created_at

  controller do
    def scoped_collection
      end_of_association_chain.includes(:user)
    end
  end

  sidebar 'Tools', only: [:index, :show_statistics] do
    para { link_to 'Show Stats', admin_mails_path, class: 'button' }
  end

  index do
    column :id
    column(:user, sortable: 'users.first_name') { |ssa| link_to ssa.user.name, admin_user_path(ssa.user) }
    column :saved_search_infos
    column :opened_at do |ssa|
      if ssa.opened_at.present?
        content_tag(:span, l(ssa.opened_at, format: :long))
      else
        content_tag(:span, '-')
      end
    end

    column :created_at

    actions
  end

  csv do
    column :id
    column :user
    column :saved_search_infos
    column :opened_at
    column :created_at
    column :updated_at
  end

end
