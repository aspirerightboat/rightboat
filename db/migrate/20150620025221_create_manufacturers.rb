class CreateManufacturers < ActiveRecord::Migration
  def change
    create_table :manufacturers do |t|
      t.string  :name,      index: true
      t.text    :description
      t.string  :weburl,    limit: 512
      t.string  :logo
      t.string  :slug,      index: true
      t.boolean :active,    index: true, default: false

      t.timestamps null: false
    end
  end
end
