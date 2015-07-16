class CreateModels < ActiveRecord::Migration
  def change
    create_table :models do |t|
      t.string :name,               index: true
      t.references :manufacturer,   index: true, foreign_key: true
      t.string :slug,               index: true
      t.boolean :active,            index: true, default: false
      t.boolean :sailing,           index: true, default: false

      t.timestamps null: false
    end
  end
end
