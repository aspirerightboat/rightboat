class CreateStripeCard < ActiveRecord::Migration
  def change
    create_table :stripe_cards do |t|
      t.references :user, index: true
      t.string :stripe_customer_id
      t.string :last4
      t.string :dynamic_last4
      t.string :brand
      t.string :country_iso
      t.integer :exp_month
      t.integer :exp_year
    end
  end
end
