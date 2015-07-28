class AddTzToImports < ActiveRecord::Migration
  def change
    add_column :imports, :tz, :string
  end
end
