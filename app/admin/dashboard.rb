ActiveAdmin.register_page 'Dashboard' do

  menu priority: 1, label: proc{ I18n.t('active_admin.dashboard') }
  now = Time.now
  beginning_of_day = now.beginning_of_day
  beginning_of_week = now.beginning_of_week
  beginning_of_month= now.beginning_of_month
  beginning_of_last_week = 1.week.ago.beginning_of_week
  beginning_of_last_month= 1.month.ago.beginning_of_month
  total_leads_last_week = Enquiry.where(created_at: beginning_of_last_week..beginning_of_week).count
  total_approved_leads_last_week = Enquiry.approved.where(created_at: beginning_of_last_week..beginning_of_week).count
  total_leads_last_month = Enquiry.where(created_at: beginning_of_last_month..beginning_of_month).count
  total_approved_leads_last_month = Enquiry.approved.where(created_at: beginning_of_last_month..beginning_of_month).count

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
                text_node ImportTrail.today.with_error.group(:import_id).count.length
              end
            end
            tr do
              td do
                text_node 'Did not run:'
              end
              td class: 'text-red' do
                text_node Import.joins('LEFT OUTER JOIN import_trails ON import_trails.import_id = imports.id').where('import_trails.import_id IS NULL OR import_trails.created_at < ?', Time.now.beginning_of_day).count
              end
            end
            tr do
              td do
                text_node 'Ran with Errors:'
              end
              td class: 'text-orange' do
                text_node ImportTrail.today.with_no_error.group(:import_id).count.length
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
                text_node 'Total Approved Leads today:'
              end
              td do
                text_node Enquiry.where('updated_at > ?', beginning_of_day).count
              end
            end
            tr do
              td do
                text_node 'Total Approved Leads this week:'
              end
              td class: 'text-green' do
                text_node Enquiry.where('updated_at > ?', beginning_of_week).count
              end
            end
            tr do
              td do
                text_node 'Total Approved Leads this month:'
              end
              td class: 'text-green' do
                text_node Enquiry.where('updated_at > ?', beginning_of_month).count
              end
            end
            tr do
              td do
              end
            end
            tr do
              td do
                text_node 'Total Approved Lead Value last week:'
              end
              td do
                text_node Enquiry.where(updated_at: beginning_of_last_week..beginning_of_week).count
              end
            end
            tr do
              td do
                text_node 'Total Approved Lead Value last month:'
              end
              td do
                text_node Enquiry.where(updated_at: beginning_of_last_month..beginning_of_month).count
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
                text_node 'Total Users:'
              end
              td do
                text_node User.count
              end
            end
            tr do
              td do
                text_node 'Total new users last week:'
              end
              td do
                text_node User.where(created_at: beginning_of_last_week..beginning_of_week).count
              end
            end
            tr do
              td do
                text_node 'Total new users last month:'
              end
              td do
                text_node User.where(created_at: beginning_of_last_month..beginning_of_month).count
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
                text_node 'Total inactive Boats:'
              end
              td class: 'text-red' do
                text_node Boat.deleted.count
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
                text_node 'Total active Power Boats:'
              end
              td do
                text_node Boat.joins('LEFT JOIN boat_types ON boats.boat_type_id = boat_types.id').where('LOWER(boat_types.name) LIKE "%power%" OR LOWER(boat_types.name) LIKE "%motor%" OR LOWER(boat_types.name) LIKE "%cruiser%"').count
              end
            end
            tr do
              td do
                text_node 'Total active Sail Boats:'
              end
              td do
                text_node Boat.joins('LEFT JOIN boat_types ON boats.boat_type_id = boat_types.id').where('LOWER(boat_types.name) LIKE "%sail%"').count
              end
            end
            tr do
              td do
                text_node 'Total not Power or Sail:'
              end
              td do
                text_node Boat.joins('LEFT JOIN boat_types ON boats.boat_type_id = boat_types.id').where('boats.boat_type_id IS NULL OR LOWER(boat_types.name) NOT LIKE "%power%" AND LOWER(boat_types.name) NOT LIKE "%motor%" AND LOWER(boat_types.name) NOT LIKE "%cruiser%" AND LOWER(boat_types.name) NOT LIKE "%sail%"').count
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
                text_node 'Total Leads last week:'
              end
              td do
                text_node total_leads_last_week
              end
            end
            tr do
              td do
                text_node 'Total Approved Leads last week:'
              end
              td class: 'text-green' do
                text_node total_approved_leads_last_week
              end
            end
            tr do
              td do
                text_node 'Total Rejected Leads last week:'
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
        panel 'Account Management' do
          table do
            tr do
              td do
                text_node ''
              end
              td do
                text_node 'Accounts'
              end
              td do
                text_node 'Total Active Boats'
              end
            end
            tr do
              td do
                text_node 'Nicky'
              end
              td do
                text_node 'xx'
              end
              td do
                text_node 'xxx'
              end
            end
            tr do
              td do
                text_node 'Chris'
              end
              td do
                text_node 'xx'
              end
              td do
                text_node 'xxx'
              end
            end
          end
        end
      end
    end
  end
end
