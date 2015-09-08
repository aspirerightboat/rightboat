class CreateUserInformations < ActiveRecord::Migration
  def change
    create_table :user_informations do |t|
      t.integer :user_id
      t.boolean :require_finance, default: false
      t.boolean :list_boat_for_sale, default: false
      t.boolean :buy_this_season, default: false
      t.boolean :looking_for_berth, default: false
    end

    add_index :user_informations, :user_id
  end
end
