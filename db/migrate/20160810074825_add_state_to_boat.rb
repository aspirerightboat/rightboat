class AddStateToBoat < ActiveRecord::Migration
  def up
    add_column :boats, :state, :string

    Country.find_by(iso: 'US').boats.active.find_each do |boat|
      state = boat.geo_location ? Rightboat::USStates.recognize(boat.geo_location) : Rightboat::USStates.recognize(boat.location)
      boat.update_column(:state, state) if state
    end
  end
end
