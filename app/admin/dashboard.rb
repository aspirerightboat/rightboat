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
          table_for ImportTrail.order('id DESC').includes(import: :user).limit(15) do |t|
            t.column('User') do |trail|
              link_to trail.import.user.name, admin_user_path(trail.import.user)
            end
            t.column('Import') { |trail| link_to trail.import.import_type, admin_import_path(trail.import) }
            t.column('Boats count') { |trail| trail.boats_count }
            t.column('New count') { |trail| trail.new_count }
            t.column('Updated count') { |trail| trail.updated_count }
            t.column('Deleted count') { |trail| trail.deleted_count }
            t.column('Not Saved count') { |trail| trail.not_saved_count }
            t.column('Images count') { |trail| trail.images_count }
            t.column('Running') do |trail|
              if trail.finished_at
                status_tag('finished', :green)
              else
                status_tag('running', :orange)
              end
            end
            t.column('Error') do |trail|
              if trail.error_msg.present?
                status_tag(trail.error_msg, :red)
              end
            end
            t.column('Time from-to (duration)') { |trail|
              started_at = l(trail.created_at, format: :short)
              finished_at = trail.finished_at ? l(trail.finished_at, format: :short) : '...'
              "#{started_at} - #{finished_at} (#{trail.duration.strftime('%H:%M:%S')})"
            }
            t.column('view log') do |trail|
              link_to 'view log', admin_import_trail_path(trail)
            end
            t.column('rerun') do |trail|
              link_to('rerun', run_admin_import_path(trail.import), method: :post, class: 'job-action') if !trail.import.running?
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
