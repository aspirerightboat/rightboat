class RemoveMarineEnquiry < ActiveRecord::Migration
  def up
    drop_table :marine_enquiries
  end
end
