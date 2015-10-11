class CreateImportTrail < ActiveRecord::Migration
  def up
    create_table :import_trails do |t|
      t.references :import, index: true
      t.string :log_path
      t.integer :boats_count, :new_count, :updated_count, :deleted_count, :images_count, default: 0
      t.string :error_msg
      t.datetime :created_at
      t.datetime :finished_at
    end

    remove_column :imports, :total_count
    remove_column :imports, :new_count
    remove_column :imports, :updated_count
    remove_column :imports, :deleted_count
    remove_column :imports, :error_msg
  end
end
