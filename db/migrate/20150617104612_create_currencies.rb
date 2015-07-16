class CreateCurrencies < ActiveRecord::Migration
  def change
    create_table :currencies do |t|
      t.string    :name
      t.float     :rate, default: 1
      t.string    :symbol
      t.boolean   :active

      t.timestamps null: false
    end

    add_index :currencies, :name
  end
end
