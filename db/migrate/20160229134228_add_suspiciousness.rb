class AddSuspiciousness < ActiveRecord::Migration
  def change
    add_column :countries, :suspicious, :boolean, default: false
    RBConfig.repair
  end
end
