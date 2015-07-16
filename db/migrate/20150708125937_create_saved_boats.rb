class CreateSavedBoats < ActiveRecord::Migration
  def change
    create_table :saved_boats do |t|
      t.references :user
      t.references :boat

      t.timestamp :created_at
      t.timestamp :deleted_at
    end

    add_index :saved_boats, [:user_id, :boat_id], unique: true
  end
end
