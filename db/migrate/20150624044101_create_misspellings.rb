class CreateMisspellings < ActiveRecord::Migration
  def change
    create_table :misspellings do |t|
      t.references :source, index: true, polymorphic: true
      t.string :alias_string

      t.timestamps null: false
    end

    add_index :misspellings, :source_type
  end
end
