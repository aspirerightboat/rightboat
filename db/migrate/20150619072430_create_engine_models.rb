class CreateEngineModels < ActiveRecord::Migration
  def change
    create_table :engine_models do |t|
      t.string :name,     index: true
      t.references :engine_manufacturer, index: true, foreign_key: true
      t.boolean :active,  index: true, default: false

      t.timestamps null: false
    end
  end
end
