ActiveAdmin.register ImportTrail do
  menu parent: 'Imports'

  filter :import_type, collection: -> { Rightboat::Imports::Base.import_types }

  controller do
    private

    def scoped_collection
      end_of_association_chain.includes(import: :user)
    end
  end

  index do
    column :id
    column :user do |trail|
      link_to trail.import.user.name, admin_user_path(trail.import.user)
    end
    column :import do |trail|
      link_to trail.import.import_type, admin_import_path(trail.import)
    end
    column :boats_count
    column :new_count
    column :updated_count
    column :deleted_count
    column :images_count
    column :not_saved_count
    column :created_at
    column :finished_at
    column :duration do |trail|
      trail.duration.strftime('%H:%M:%S')
    end
    column :error do |trail|
      status_tag(trail.error_msg, :red) if trail.error_msg.present?
    end

    actions
  end

  show do
    attributes_table do
      row :id
      row :import do |trail|
        link_to trail.import.import_type, admin_import_path(trail.import)
      end
      row :boats_count
      row :new_count
      row :updated_count
      row :deleted_count
      row :images_count
      row :not_saved_count
      row :error_msg
      row :created_at
      row :finished_at
    end
    panel 'Import Log' do
      log_path = import_trail.log_path
      if log_path && File.exists?(log_path)
        File.open(log_path, 'r').each_line do |line|
          div { "#{line}<br>".html_safe }
        end
      end
    end
  end

end
