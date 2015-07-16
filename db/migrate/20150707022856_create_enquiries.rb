class CreateEnquiries < ActiveRecord::Migration
  def change
    create_table :enquiries do |t|
      t.references :user, index: true, foreign_key: true
      t.references :boat, index: true, foreign_key: true
      t.string :title
      t.string :first_name
      t.string :surname
      t.string :email
      t.string :phone
      t.text :message
      t.string :remote_ip
      t.string :browser
      t.string :token, index: true, limit: 64

      t.timestamp :deleted_at
      t.timestamps null: false
    end
  end
end
