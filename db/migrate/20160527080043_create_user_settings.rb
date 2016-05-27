class CreateUserSettings < ActiveRecord::Migration
  def change
    create_table :user_settings do |t|
      t.integer :user_id
      t.string :country_iso
      t.string :currency_name
      t.string :length_unit
      t.string :boat_type #interested_in_boat_type
    end

    add_index :user_settings, :user_id
  end
end
