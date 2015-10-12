class AddNotSavedCountToImportTrail < ActiveRecord::Migration
  def change
    add_column :import_trails, :not_saved_count, :integer, default: 0
  end
end
