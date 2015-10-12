class AddLastImportTrailToImport < ActiveRecord::Migration
  def change
    add_column :imports, :last_import_trail_id, :integer
    add_index :imports, :last_import_trail_id
  end
end
