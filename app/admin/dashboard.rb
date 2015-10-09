ActiveAdmin.register_page 'Dashboard' do

  menu priority: 1, label: proc{ I18n.t('active_admin.dashboard') }

  content title: proc{ I18n.t('active_admin.dashboard') } do
    div class: 'blank_slate_container', id: 'dashboard_default_message' do
      span class: 'blank_slate' do
        span 'Welcome to Rightboat Admin Panel'
        small 'Please contact develop team for the question and/or issue.'
      end
    end

    columns do
      column do
        panel 'Import stats' do
          table_for Import.active do |t|
            t.column('Import') { |import| link_to import.import_type, admin_import_path(import) }
            t.column('Total count') { |import| import.total_count }
            t.column('New count') { |import| import.new_count }
            t.column('Updated count') { |import| import.updated_count }
            t.column('Deleted count') { |import| import.deleted_count }
            t.column('Status') do |import|
              status = import.status
              case status
                when /running/i then status_tag(status, :ok)
                when /loading/i then status_tag(status, :yes)
                when /waiting/i then status_tag(status, :no)
                when /inactive/i then status_tag(status, :error)
              end
            end
            t.column('Last run at') { |import| import.last_ran_at.blank? ? 'never' : l(import.last_ran_at, format: :long) }
            t.column('Error') do |import|
              unless import.error_msg.blank?
                status_tag import.error_msg.try(:humanize), :error
              end
            end
          end
        end
      end

    #   column do
    #     panel "Info" do
    #       para "Welcome to ActiveAdmin."
    #     end
    #   end
    end
  end # content
end
