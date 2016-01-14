class AddOfferStatusToBoat < ActiveRecord::Migration
  def change
    add_column :boats, :offer_status, :string, default: 'available'
    Boat.reset_column_information
    Boat.where(under_offer: true).update_all(offer_status: 'under_offer')
    remove_column :boats, :under_offer
  end
end
