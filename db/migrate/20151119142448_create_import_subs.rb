class CreateImportSubs < ActiveRecord::Migration
  def change
    create_table :import_subs do |t|
      t.string :import_type
      t.integer :import_id
      t.string :remove_regex
      t.text :sample_text

      t.timestamps
    end
  end
end
