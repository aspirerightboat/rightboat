class CreateBoatClassCodes < ActiveRecord::Migration
  def change
    create_table :boat_class_codes do |t|
      t.string :name
    end
  end
end
