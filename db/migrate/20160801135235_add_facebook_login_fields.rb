class AddFacebookLoginFields < ActiveRecord::Migration
  def change
    create_table :facebook_user_infos do |t|
      t.references :user, index: true
      t.string :uid, index: true
      t.string :email
      t.string :first_name
      t.string :last_name
      t.string :name
      t.string :image_url
      t.string :gender
      t.string :profile_url
      t.string :locale
      t.integer :age_min
      t.integer :age_max
      t.integer :timezone
    end
  end
end
