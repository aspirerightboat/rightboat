class CreateCountries < ActiveRecord::Migration
  def change
    create_table :countries do |t|
      t.string      :iso
      t.string      :name
      t.string      :slug
      t.text        :description
      t.references  :currency, index: true, foreign_key: true
      t.boolean     :active,   index: true, default: false

      t.timestamps  null: false
    end

    add_index :countries, :iso
    add_index :countries, :slug
  end
end
