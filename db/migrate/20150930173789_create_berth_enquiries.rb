class CreateBerthEnquiries < ActiveRecord::Migration
  def change
    create_table :berth_enquiries do |t|
      t.integer  :user_id
      t.boolean  :buy,          default: false
      t.boolean  :rent,         default: false
      t.boolean  :home,         default: false
      t.boolean  :short_term,   default: false
      t.float    :length_min,   default: 0
      t.float    :length_max
      t.string   :length_unit
      t.string   :location
      t.float    :latitude
      t.float    :longitude

      t.timestamps
    end

    add_index :berth_enquiries, :user_id
  end
end
