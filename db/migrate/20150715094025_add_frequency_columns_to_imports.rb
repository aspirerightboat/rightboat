class AddFrequencyColumnsToImports < ActiveRecord::Migration
  def change
    add_column :imports, :use_proxy, :boolean, default: false
    add_column :imports, :frequency_unit, :string, limit: 16, default: 1
    add_column :imports, :frequency_quantity, :integer
    add_column :imports, :at, :string,    limit: 64
    add_column :imports, :pid, :integer
    add_column :imports, :queued_at, :datetime
  end
end
