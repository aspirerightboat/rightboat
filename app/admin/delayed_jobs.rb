ActiveAdmin.register Delayed::Job do

  menu parent: 'Other', label: 'Delayed Jobs'

  config.sort_order = 'id_desc'

  filter :priority
  filter :attempts
  filter :last_error
  filter :run_at
  filter :locked_at
  filter :failed_at
  filter :queue, as: :select, collection: %w(default mailers import_images)
  filter :created_at
  filter :updated_at

  actions :all, except: [:new]

  index do
    id_column
    column :priority
    column :attempts
    column :handler
    column :last_error
    column :run_at
    column :locked_at
    column :failed_at
    column :locked_by
    column :queue
    column :created_at

    actions
  end

end
