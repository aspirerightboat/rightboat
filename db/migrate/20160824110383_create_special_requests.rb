class CreateSpecialRequests < ActiveRecord::Migration
  def change
    create_table :special_requests do |t|
      t.integer :user_id
      t.integer :request_type
    end

    add_index :special_requests, :user_id
    add_index :special_requests, :request_type
  end
end
