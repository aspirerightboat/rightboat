class CreateHomeSettings < ActiveRecord::Migration
  def change
    create_table :home_settings do |t|
      t.string :boat_type
      t.string :attached_media
    end

    add_index :home_settings, :boat_type
  end
end
