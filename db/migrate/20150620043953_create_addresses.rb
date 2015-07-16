class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.string          :line1
      t.string          :line2
      t.string          :town_city
      t.string          :county
      t.references      :country,     index: true, foreign_key: true
      t.string          :zip
      t.references      :addressible, index: true, polymorphic: true

      t.timestamps null: false
    end
  end
end
