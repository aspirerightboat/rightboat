class AddStateToBoat < ActiveRecord::Migration

  def up
    add_column :boats, :state, :string

    Country.find_by(iso: 'US').boats.active.includes(:country).find_each do |boat|
      location = [boat.location, boat.country&.name].reject(&:blank?).join(', ')
      state = Rightboat::USStates.recognize(location) || Rightboat::USStates.recognize(boat.geo_location)
      boat.update(state: state) if state && boat.state != state
    end
  end

end
