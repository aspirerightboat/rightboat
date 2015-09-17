class AddFieldsToImports < ActiveRecord::Migration
  def change
    add_column :imports, :total_count,    :integer, default: 0
    add_column :imports, :new_count,      :integer, default: 0
    add_column :imports, :updated_count,  :integer, default: 0
    add_column :imports, :deleted_count,  :integer, default: 0
    add_column :imports, :error_msg,      :string
  end
end
