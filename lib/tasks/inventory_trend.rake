namespace :inventory_trend do
  desc 'Store inventory trend'
  task store: :environment do
    InventoryTrend.create(
      total_boats: Boat.not_deleted.count,
      power_boats: Boat.not_deleted.power.count,
      sail_boats: Boat.not_deleted.sail.count,
      not_power_or_sail: Boat.not_deleted.not_power_or_sail.count,
    )
  end
end
