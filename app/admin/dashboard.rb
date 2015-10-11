ActiveAdmin.register_page 'Dashboard' do

  menu priority: 1, label: proc{ I18n.t('active_admin.dashboard') }

  content title: proc{ I18n.t('active_admin.dashboard') } do
    # div class: 'blank_slate_container', id: 'dashboard_default_message' do
    #   span class: 'blank_slate' do
    #     span 'Welcome to Rightboat Admin Panel'
    #     small 'Please contact develop team for the question and/or issue.'
    #   end
    # end

    columns do
      column do
        panel 'Recent Imports runned' do
          table_for ImportTrail.order('id DESC').includes(:import).limit(15) do |t|
            t.column('Import') { |trail| link_to trail.import.import_type, admin_import_path(trail.import) }
            t.column('Boats count') { |trail| trail.boats_count }
            t.column('New count') { |trail| trail.new_count }
            t.column('Updated count') { |trail| trail.updated_count }
            t.column('Deleted count') { |trail| trail.deleted_count }
            t.column('Images count') { |trail| trail.images_count }
            t.column('Status') do |trail|
              if trail.error_msg.present?
                status_tag(error_msg, :red)
              elsif trail.finished_at
                status_tag('finished', :green)
              else
                status_tag('running', :orange)
              end
            end
            t.column('Time from-to (duration)') { |trail|
              started_at = l(trail.created_at, format: :short)
              finished_at = trail.finished_at ? l(trail.finished_at, format: :short) : '...'
              duration = Time.at(((trail.finished_at || Time.current) - trail.created_at)).utc.strftime('%H:%M:%S')
              "#{started_at} - #{finished_at} (#{duration})"
            }
            t.column('view log') do |trail|
              link_to 'view log', admin_import_trail_path(trail)
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
