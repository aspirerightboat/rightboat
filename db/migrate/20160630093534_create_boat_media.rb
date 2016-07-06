class CreateBoatMedia < ActiveRecord::Migration
  def change
    create_table :boat_media do |t|
      t.string :source_url
      t.string :attachment_title
      t.string :type_string
      t.text :alternate_text
      t.integer :boat_id
      t.datetime :last_modified
      t.datetime :deleted_at
    end

    add_index :boat_media, :boat_id
    add_index :boat_media, :source_url
  end
end
