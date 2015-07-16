class CreateOffices < ActiveRecord::Migration
  def change
    create_table :offices do |t|
      t.string :name,       index: true
      t.string :contact_name
      t.string :daytime_phone
      t.string :evening_phone
      t.string :mobile
      t.string :fax
      t.string :email
      t.string :website
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
