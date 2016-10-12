module Rightboat
  class BoatStats
    def self.boat_views_leads(boat, months_count)
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

    def self.general_broker_stats(broker, months_count)
      {
          views_monthly: broker_views_monthly(broker, months_count),
          leads_monthly: broker_leads_monthly(broker, months_count),
          inventory_monthly: broker_inventory_monthly(broker, months_count),
      }
    end

    def self.broker_views_monthly(broker, months_count)
      views = UserActivity.joins(:boat).where(boats: {user_id: broker.id})
                  .where(user_activities: {kind: :boat_view})
                  .where('user_activities.created_at > ?', months_count.months.ago.to_date)
                  .group('custom_date')
                  .pluck("DATE_FORMAT(user_activities.created_at, '%Y-%m') custom_date, COUNT(*)").to_h

      monthly_performance_chart(%w(Date Views), views, months_count)
    end

    def self.broker_leads_monthly(broker, months_count)
      leads = Lead.joins(:boat).where(boats: {user_id: broker.id})
                  .where(leads: {status: %w(pending approved invoiced)})
                  .where('leads.created_at > ?', months_count.months.ago.to_date)
                  .group('custom_date, leads.status')
                  .pluck("DATE_FORMAT(leads.created_at, '%Y-%m') custom_date, leads.status, COUNT(*)")
      leads_by_date = leads.group_by(&:first)

      res = [%w(Date Invoiced Approved Pending)]

      months_count.downto(0).each do |i|
        date = i.months.ago.strftime('%Y-%m')
        arr_by_status = leads_by_date[date]&.index_by(&:second)
        res << [date,
                arr_by_status&.dig('invoiced')&.last.to_i,
                arr_by_status&.dig('approved')&.last.to_i,
                arr_by_status&.dig('pending')&.last.to_i]
      end

      res
    end

    def self.broker_inventory_monthly(broker, months_count)
      created_combined = Boat.where(user_id: broker.id)
                             .group('date_key, del_present')
                             .pluck("DATE_FORMAT(created_at, '%Y-%m') date_key, IF(deleted_at,1,0) del_present, COUNT(*)")
      created = {}
      created_deleted = {}
      created_combined.each { |date_key, del_present, cnt| (del_present == 0 ? created : created_deleted)[date_key] = cnt }

      deleted = Boat.where(user_id: broker.id).where.not(deleted_at: nil)
                    .group('custom_date')
                    .pluck("DATE_FORMAT(deleted_at, '%Y-%m') custom_date, COUNT(*)").to_h

      deadline = months_count.months.ago.strftime('%Y-%m')
      all_keys_hash = created.dup.merge!(created_deleted).merge!(deleted)
      existing_in_past = all_keys_hash.keys.select { |k| k < deadline }.sort.inject(0) do |sum, k|
        created_only = (created[k] || 0)
        deleted_only = (deleted[k] || 0) - (created_deleted[k] || 0)
        sum + created_only - deleted_only
      end

      existing = existing_in_past
      data = months_count.downto(0).map do |i|
        key = i.months.ago.strftime('%Y-%m')
        created_only = created[key] || 0
        created_and_deleted = created_deleted[key] || 0
        deleted_only = (deleted[key] || 0) - created_and_deleted
        res = [key, existing, deleted_only, created_and_deleted, created_only]
        existing += created_only - deleted_only
        res
      end

      [['Date', 'Existing', 'Deleted', 'Created & Deleted', 'Created']].concat(data)
    end

    def self.monthly_performance_chart(header_columns, data_hash, months_count)
      data = months_count.downto(0).map do |i|
        key = i.months.ago.strftime('%Y-%m')
        [key, data_hash[key] || 0]
      end

      [header_columns].concat(data)
    end
  end
end
