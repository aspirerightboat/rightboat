class CreateVatRates < ActiveRecord::Migration
  def change
    create_table :vat_rates do |t|
      t.string  :name,    index: true
      t.boolean :active,  index: true, default: false

      t.timestamps null: false
    end
  end
end
