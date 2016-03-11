ActiveAdmin.register ErrorEvent do
  menu parent: 'Other'

  config.sort_order = 'id_desc'

  filter :error_type_cont, label: 'Error Type Contains'
  filter :message_cont, label: 'Message Contains'

  index do
    id_column
    column :error_type
    column :message
    column(:backtrace) { |record| truncate(record.backtrace, length: 100) }
    column :context
    column :notified
    column(:created_at) { |record| time_ago_with_hint(record.created_at) }

    actions
  end

  show do
    attributes_table do
      row :error_type
      row :message
      row(:backtrace) { simple_format(error_event.backtrace) }
      row :context
      row :notified
      row :created_at
      row :updated_at
    end
  end

end
