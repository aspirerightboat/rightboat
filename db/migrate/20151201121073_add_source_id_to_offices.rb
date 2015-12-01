class AddSourceIdToOffices < ActiveRecord::Migration
  def change
    add_column :offices, :source_id, :string
    add_index :offices, :source_id
  end
end
