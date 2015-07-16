class CreateEngineManufacturers < ActiveRecord::Migration
  def change
    create_table :engine_manufacturers do |t|
      t.string  :name,    index: true
      t.string  :display_name
      t.boolean :active,  index: true, default: false

      t.timestamps null: false
    end
  end
end
