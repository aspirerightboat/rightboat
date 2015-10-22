class RemoveOfficesForeignKey < ActiveRecord::Migration
  def change
    remove_foreign_key 'offices', 'users'
  end
end
