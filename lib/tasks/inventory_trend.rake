namespace :inventory_trend do
  desc 'Store inventory trend'
  task store: :environment do
    InventoryTrend.create(
      total_boats: Boat.active.count,
      power_boats: Boat.active.power.count,
      sail_boats: Boat.active.sail.count,
      not_power_or_sail: Boat.active.not_power_or_sail.count,
    )
  end
end
