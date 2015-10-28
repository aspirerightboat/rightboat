class CreateInsurances < ActiveRecord::Migration
  def change
    create_table :insurances do |t|
      t.references :user, index: true
      t.references :manufacturer, index: true
      t.references :model, index: true
      t.string :type_of_cover
      t.integer :age_of_vessel
      t.references :country, index: true
      t.string :where_kept
      t.float :total_value
      t.string :currency
      t.integer :years_no_claim

      t.timestamps
    end
  end
end
