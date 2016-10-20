class AddOverwriteBrokerToImport < ActiveRecord::Migration[5.0]
  def change
    add_column :imports, :overwrite_broker, :boolean
  end
end
