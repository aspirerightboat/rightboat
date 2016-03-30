ActiveAdmin.register SavedSearchesAlert do
  menu parent: 'Users'

  config.sort_order = 'id_desc'
  permit_params :user_id, :saved_search_ids, :opened_at

  filter :user
  filter :saved_search_ids
  filter :opened_at
  filter :created_at
  controller do
    def scoped_collection
      end_of_association_chain.includes(:user)
    end
  end

  index do
    column :id
    column(:user, sortable: 'users.first_name') { |ssa| link_to ssa.user.name, admin_user_path(ssa.user) }
    column(:saved_search_ids) do |ssa|
      links = []
      SavedSearch.where(id: ssa.saved_search_ids).each do |search|
        links << link_to(search.id, admin_saved_search_path(search))
      end
      raw links.join(', ')
    end

    column :opened_at do |ssa|

      if ssa.opened_at.present?
        res = []
        res << content_tag(:span, "opened", class: "status_tag yes")
        res << content_tag(:span, l(ssa.opened_at, format: :full_datetime))
        res.join(" ").html_safe
      end
    end

    column :created_at

    actions
  end

  csv do
    column :id
    column :user
    column :saved_search_ids
    column :opened_at
    column :created_at
    column :updated_at
  end

end
