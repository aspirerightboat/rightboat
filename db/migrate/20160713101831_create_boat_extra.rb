class CreateBoatExtra < ActiveRecord::Migration
  def change
    create_table :boat_extras do |t|
      t.references :boat

      t.text :short_description
      t.text :description
      t.text :owners_comment
      t.text :disclaimer

      t.datetime :deleted_at
      t.timestamps
    end

    Boat.find_each do |boat|
      extra = boat.build_extra
      extra.short_description = boat.short_description
      extra.description = boat.description
      extra.owners_comment = boat.owners_comment
      extra.save!
    end

    remove_column :boats, :short_description
    remove_column :boats, :description
    remove_column :boats, :owners_comment
  end
end
