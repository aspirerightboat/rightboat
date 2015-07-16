class CreateBoatSpecifications < ActiveRecord::Migration
  def change
    create_table :boat_specifications do |t|
      t.references :specification, index: true, foreign_key: true
      t.references :boat, index: true, foreign_key: true
      t.string :value

      t.timestamps null: false
    end
  end
end
