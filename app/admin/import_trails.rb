ActiveAdmin.register ImportTrail do
  menu parent: 'Imports'

  # filter :import_type, collection: -> { Rightboat::Imports::Base.source_types }

  controller do
    private

    def scoped_collection
      end_of_association_chain.includes(:import)
    end
  end

  index do
    column :id
    column :import do |trail|
      link_to trail.import.import_type, admin_import_path(trail.import)
    end
    column :boats_count
    column :new_count
    column :updated_count
    column :deleted_count
    column :images_count
    column :created_at
    column :finished_at

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
