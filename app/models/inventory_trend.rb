class InventoryTrend < ActiveRecord::Base

  validates_presence_of :total_boats, :power_boats, :sail_boats, :not_power_or_sail
  validates_numericality_of :total_boats, :power_boats, :sail_boats, :not_power_or_sail, 
                            integer: true, greater_than_or_equal_to: 0
end
