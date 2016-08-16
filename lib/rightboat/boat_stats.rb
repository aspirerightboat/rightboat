module Rightboat
  class BoatStats
    def self.boat_views_leads(boat)
      months_count = 5
      views = UserActivity.where(boat_id: boat.id, kind: :boat_view)
                  .where('created_at > ?', months_count.months.ago.to_date)
                  .group('custom_date')
                  .pluck("DATE_FORMAT(created_at, '%Y-%m') custom_date, COUNT(*)").to_h
      leads = Lead.where(boat_id: boat.id, status: %w(approved invoiced))
                  .where('created_at > ?', months_count.months.ago.to_date)
                  .group('custom_date')
                  .pluck("DATE_FORMAT(created_at, '%Y-%m') custom_date, COUNT(*)").to_h
      data = months_count.downto(0).map do |i|
        key = i.months.ago.strftime('%Y-%m')
        [key, views[key] || 0, leads[key] || 0]
      end

      [%w(Date Views Leads)].concat(data)
    end

    def self.general_broker_stats(broker)
      months_count = 5
      views = UserActivity.joins(:boat).where(boats: {user_id: broker.id})
                  .where(user_activities: {kind: :boat_view})
                  .where('user_activities.created_at > ?', months_count.months.ago.to_date)
                  .group('custom_date')
                  .pluck("DATE_FORMAT(user_activities.created_at, '%Y-%m') custom_date, COUNT(*)").to_h
      leads = Lead.joins(:boat).where(boats: {user_id: broker.id})
                  .where(leads: {status: %w(approved invoiced)})
                  .where('leads.created_at > ?', months_count.months.ago.to_date)
                  .group('custom_date')
                  .pluck("DATE_FORMAT(leads.created_at, '%Y-%m') custom_date, COUNT(*)").to_h

      data = months_count.downto(0).map do |i|
        key = i.months.ago.strftime('%Y-%m')
        [key, (views[key] || 0) / 1000.0, leads[key] || 0]
      end

      [['Date', 'Views', 'Leads (Thousands)']].concat(data)
    end
  end
end
