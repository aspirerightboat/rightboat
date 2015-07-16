class CreateBoatImages < ActiveRecord::Migration
  def change
    create_table :boat_images do |t|
      t.string :source_ref
      t.string :source_url
      t.string :file
      t.integer :position
      t.datetime :http_last_modified
      t.references :boat, index: true, foreign_key: true

      t.timestamps null: false
    end

    add_index :boat_images, :position
    add_index :boat_images, :source_url
  end
end
