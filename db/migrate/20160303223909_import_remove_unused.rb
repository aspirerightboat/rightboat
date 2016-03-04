class ImportRemoveUnused < ActiveRecord::Migration
  def change
    remove_column :imports, :use_proxy
    remove_column :imports, :frequency_quantity
    change_column :imports, :frequency_unit, :string, default: 'day'
    change_column :imports, :at, :string, default: '00:00', limit: 8
    change_column :imports, :tz, :string, default: 'UTC'
  end
end
