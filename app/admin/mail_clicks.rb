ActiveAdmin.register MailClick do
  menu parent: 'Mails'

  config.sort_order = 'id_desc'
  permit_params :user_id, :saved_searches_alert_id, :url, :action_fullname, :email_sent_at

  filter :user
  filter :saved_searches_alert_id
  filter :url_cont, label: 'URL Contains'
  filter :action_fullname_cont, label: 'Action Fullname Contains'
  filter :created_at
  filter :email_sent_at

  sidebar 'Tools', only: [:index, :show_statistics] do
    para { link_to 'Show Stats', admin_mails_path, class: 'button' }
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes(:user)
    end
  end

  index do
    column :id
    column :url
    column :action_fullname

    column(:user, sortable: 'users.first_name') { |ssa| link_to ssa.user.name, admin_user_path(ssa.user) }
    column(:saved_searches_alert_id) do |mail_click|
      link_to(mail_click.saved_searches_alert_id, admin_saved_searches_alert_path(mail_click.saved_searches_alert_id))
    end

    column :email_sent_at
    column :created_at

    actions
  end

  csv do
    column :id
    column :url
    column :action_fullname
    column :user
    column :saved_searches_alert_id
    column :email_sent_at
    column :created_at
    column :updated_at
  end
end
