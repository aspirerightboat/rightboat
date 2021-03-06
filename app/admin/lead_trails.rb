ActiveAdmin.register LeadTrail do
  menu parent: 'Leads'

  config.sort_order = 'id_desc'
  permit_params :user_id, :lead_id, :new_status

  filter :user, collection: -> { User.all }
  filter :lead_id
  filter :new_status

  controller do
    def scoped_collection
      end_of_association_chain.includes(:user, :lead)
    end
  end

  index do
    column(:user) { |lt| link_to(lt.user.name, admin_user_path(lt.user)) if lt.user }
    column(:lead) { |lt| link_to lt.lead.id, admin_lead_path(lt.lead) }
    column :new_status
    column :comments
    column :created_at

    actions
  end

  show do
    attributes_table do
      row :id
      row :user
      row :lead
      row :new_status
      row :comments
      row :bad_quality_reason
      row :bad_quality_comment
    end
  end

  form do |f|
    f.inputs do
      f.input :new_status, as: :select, collection: Lead::STATUSES.map { |s| [s.titleize, s] }, include_blank: false
    end

    f.actions
  end

end
