class CreateImports < ActiveRecord::Migration
  def change
    create_table :imports do |t|
      t.references :user, index: true, foreign_key: true
      t.text :param
      t.datetime :last_ran_at
      t.boolean :active
      t.integer :threads, default: 1
      t.string :import_type

      t.timestamps null: false
    end
  end
end
