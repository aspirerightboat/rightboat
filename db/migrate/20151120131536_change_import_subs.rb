class ChangeImportSubs < ActiveRecord::Migration
  def change
    add_column :import_subs, :use_regex, :boolean, default: true
    rename_column :import_subs, :remove_regex, :from
    add_column :import_subs, :to, :string
  end
end
