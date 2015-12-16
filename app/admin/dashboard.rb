ActiveAdmin.register_page 'Dashboard' do

  menu priority: 1, label: proc{ I18n.t('active_admin.dashboard') }
  now = Time.current
  day_ago = 1.day.ago
  beginning_of_day = now.beginning_of_day
  beginning_of_week = now.beginning_of_week
  beginning_of_month= now.beginning_of_month
  beginning_of_last_week = 1.week.ago.beginning_of_week
  beginning_of_last_month= 1.month.ago.beginning_of_month
  total_leads_last_week = Enquiry.where(created_at: beginning_of_last_week..beginning_of_week).count
  total_approved_leads_last_week = Enquiry.approved.where(updated_at: beginning_of_last_week..beginning_of_week).count
  total_leads_last_month = Enquiry.where(created_at: beginning_of_last_month..beginning_of_month).count
  total_approved_leads_last_month = Enquiry.approved.where(updated_at: beginning_of_last_month..beginning_of_month).count

  content title: proc{ I18n.t('active_admin.dashboard') } do
    columns do
      column do
        panel 'Imports - Last 24 hours' do
          table do
            tr do
              td do
                text_node 'Total Imports:'
              end
              td do
                text_node Import.count
              end
            end
            tr do
              td do
                text_node 'Ran with no Errors:'
              end
              td class: 'text-green' do
                text_node ImportTrail.last_day.without_errors.group(:import_id).count.length
              end
            end
            tr do
              td do
                text_node 'Run Fault:'
              end
              td class: 'text-red' do
                link_to ImportTrail.last_day.where(error_msg: ['Unexpected Error', 'Import Blank']).group(:import_id).count.length, admin_import_trails_path(q: {created_at_gteq: day_ago.strftime('%F'), error_msg_in: ['Unexpected Error', 'Import Blank']})
              end
            end
            tr do
              td do
                text_node 'Ran, but with Errors:'
              end
              td class: 'text-orange' do
                link_to ImportTrail.last_day.with_errors.group(:import_id).count.length, admin_import_trails_path(q: {created_at_gteq: day_ago.strftime('%F'), error_msg_present: 1})
              end
            end
            tr do
              td do
                text_node 'Inactive Imports:'
              end
              td do
                link_to Import.inactive.count, admin_imports_path(q: {active_eq: false})
              end
            end
          end
        end
      end

      column do
        panel 'Leads Tracker' do
          table do
            tr do
              td do
                text_node 'Total Leads today:'
              end
              td do
                text_node Enquiry.where('created_at > ?', beginning_of_day).count
              end
            end
            tr do
              td do
                text_node 'Total Approved Leads today:'
              end
              td do
                text_node Enquiry.approved.where('updated_at > ?', beginning_of_day).count
              end
            end
            tr do
              td do
                text_node "Total Approved Leads this week (Mon-#{now.strftime('%a')}):"
              end
              td class: 'text-green' do
                text_node Enquiry.approved.where('updated_at > ?', beginning_of_week).count
              end
            end
            tr do
              td do
                text_node 'Total Approved Leads this month:'
              end
              td class: 'text-green' do
                text_node Enquiry.approved.where('updated_at > ?', beginning_of_month).count
              end
            end
            tr do
              td do
              end
            end
            tr do
              td do
                text_node 'Total Approved Lead Value last week (Mon-Sun):'
              end
              td do
                text_node Enquiry.approved.where(created_at: beginning_of_last_week..beginning_of_week).count
              end
            end
            tr do
              td do
                text_node 'Total Approved Lead Value last month:'
              end
              td do
                text_node Enquiry.approved.where(created_at: beginning_of_last_month..beginning_of_month).count
              end
            end
          end
        end
      end

      column do
        panel 'User Activity' do
          table do
            tr do
              td do
                text_node 'Total Private Users:'
              end
              td do
                text_node User.general.count
              end
            end
            tr do
              td do
                text_node "Total new Private Users this week (Mon-#{now.strftime('%a')}):"
              end
              td do
                text_node User.general.where('created_at > ?', beginning_of_week).count
              end
            end
            tr do
              td do
                text_node 'Total new Private Users last week (Mon-Sun):'
              end
              td do
                text_node User.general.where(created_at: beginning_of_last_week..beginning_of_week).count
              end
            end
            tr do
              td do
                text_node 'Total new Private Users last month:'
              end
              td do
                text_node User.general.where(created_at: beginning_of_last_month..beginning_of_month).count
              end
            end
          end
        end
      end
    end

    columns do
      column do
        panel 'Boat Inventory' do
          table do
            tr do
              td do
                text_node 'Total Boats:'
              end
              td do
                text_node Boat.count
              end
            end
            tr do
              td do
                text_node 'Total active Boats:'
              end
              td class: 'text-green' do
                text_node Boat.not_deleted.count
              end
            end
            tr do
              td do
                text_node 'Total inactive Boats:'
              end
              td class: 'text-red' do
                text_node Boat.deleted.count
              end
            end
            tr do
              td do
                text_node 'Total active Power Boats:'
              end
              td do
                text_node Boat.not_deleted.joins('LEFT JOIN boat_types ON boats.boat_type_id = boat_types.id').where('LOWER(boat_types.name) LIKE "%power%" OR LOWER(boat_types.name) LIKE "%motor%" OR LOWER(boat_types.name) LIKE "%cruiser%"').count
              end
            end
            tr do
              td do
                text_node 'Total active Sail Boats:'
              end
              td do
                text_node Boat.not_deleted.joins('LEFT JOIN boat_types ON boats.boat_type_id = boat_types.id').where('LOWER(boat_types.name) LIKE "%sail%"').count
              end
            end
            tr do
              td do
                text_node 'Total active, not Power or Sail'
              end
              td do
                text_node Boat.not_deleted.joins('LEFT JOIN boat_types ON boats.boat_type_id = boat_types.id').where('boats.boat_type_id IS NULL OR LOWER(boat_types.name) NOT LIKE "%power%" AND LOWER(boat_types.name) NOT LIKE "%motor%" AND LOWER(boat_types.name) NOT LIKE "%cruiser%" AND LOWER(boat_types.name) NOT LIKE "%sail%"').count
              end
            end
          end
        end
      end

      column do
        panel 'Leads Analysis' do
          table do
            tr do
              td do
                text_node 'Total Leads last week (Mon-Sun):'
              end
              td do
                text_node total_leads_last_week
              end
            end
            tr do
              td do
                text_node 'Total Approved Leads last week (Mon-Sun):'
              end
              td class: 'text-green' do
                text_node total_approved_leads_last_week
              end
            end
            tr do
              td do
                text_node 'Total Rejected Leads last week (Mon-Sun):'
              end
              td class: 'text-red' do
                text_node Enquiry.rejected.where(updated_at: beginning_of_last_week..beginning_of_week).count
              end
            end
            tr do
              td do
                text_node 'Approval Percentage:'
              end
              td do
                text_node approved_percentage(total_leads_last_week, total_approved_leads_last_week)
              end
            end
            tr do
              td do
              end
            end
            tr do
              td do
                text_node 'Total Leads last month:'
              end
              td do
                text_node total_leads_last_month
              end
            end
            tr do
              td do
                text_node 'Total Approved Leads last month:'
              end
              td class: 'text-green' do
                text_node total_approved_leads_last_month
              end
            end
            tr do
              td do
                text_node 'Total Rejected Leads last month:'
              end
              td class: 'text-red' do
                text_node Enquiry.rejected.where(updated_at: beginning_of_last_month..beginning_of_month).count
              end
            end
            tr do
              td do
                text_node 'Approval Percentage:'
              end
              td do
                text_node approved_percentage(total_leads_last_month, total_approved_leads_last_month)
              end
            end
          end
        end
      end

      column do
        panel 'Broker status' do
          table do
            tr do
              td do
                text_node 'Total Brokers'
              end
              td do
                text_node User.companies.count
              end
            end
            tr do
              td do
                text_node 'Brokers with Active Boats'
              end
              td class: 'text-green' do
                link_to User.companies.where('boats_count > ?', 0).count, admin_users_path(q: {role_eq: User::ROLES['COMPANY'], boats_count_greater_than: 0})
              end
            end
            tr do
              td do
                text_node 'Brokers with no Active Boats'
              end
              td class: 'text-orange' do
                link_to User.companies.where(boats_count: 0).count, admin_users_path(q: {role_eq: User::ROLES['COMPANY'], boats_count_eq: 0})
              end
            end
          end
        end
      end
    end
  end
end
