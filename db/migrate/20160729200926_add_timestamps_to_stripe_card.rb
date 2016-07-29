class AddTimestampsToStripeCard < ActiveRecord::Migration
  def change
    add_column :stripe_cards, :updated_at, :datetime
    add_column :stripe_cards, :created_at, :datetime
  end
end
