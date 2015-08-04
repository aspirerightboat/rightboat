class AddVisibleToSpecifications < ActiveRecord::Migration
  def change
    add_column :specifications, :visible, :boolean, index: true
  end
end
