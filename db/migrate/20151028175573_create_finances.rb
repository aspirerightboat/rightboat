class CreateFinances < ActiveRecord::Migration
  def change
    create_table :finances do |t|
      t.references :user, index: true
      t.references :manufacturer, index: true
      t.references :model, index: true
      t.integer :age_of_vessel
      t.references :country, index: true
      t.float :price
      t.string :price_currency
      t.float :loan_amount
      t.string :loan_amount_currency

      t.timestamps
    end
  end
end
