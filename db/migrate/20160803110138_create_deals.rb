class CreateDeals < ActiveRecord::Migration
  def change
    create_table :deals do |t|
      t.references :user, index: true
      t.string :deal_type, default: 'standard'
      t.text :charges_text
      t.float :flat_lead_price
      t.float :flat_month_price
      t.references :currency
      t.datetime :trial_started_at
      t.datetime :trial_ended_at

      t.timestamps
    end
  end
end
