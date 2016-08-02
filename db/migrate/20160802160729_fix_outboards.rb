class FixOutboards < ActiveRecord::Migration
  def change
    Boat.inactive.where('created_at > ?', 2.weeks.ago).each do |boat|
      boat.save
    end
  end
end
