class CreateLeadTrails < ActiveRecord::Migration
  def change
    create_table :lead_trails do |t|
      t.integer :lead_id
      t.references :user, index: true
      t.string :new_status
      t.datetime :created_at

      t.index :lead_id
    end
  end
end
