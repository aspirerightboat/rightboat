ActiveAdmin.register Import do
  menu priority: 3

  filter :user, collection: -> { User.companies }
  filter :active
  filter :import_type, as: :select, collection: -> { Rightboat::Imports::Base.import_types }
  filter :last_ran_at

  controller do
    before_filter :check_running_job, only: [:edit, :update, :destroy]

    def import_params
      permitted_param_names = [
        :import_type, :active, :use_proxy, :user_id, :threads,
        :frequency_unit, :frequency_quantity, :at, :tz
      ]

      params.require(:import).permit(permitted_param_names).tap do |w|
        w[:param] = params[:import][:param]
      end
    end

    private

    def check_running_job
      if resource.running?
        flash[:warning] = "You can not manage this import since it's in running status. Please stop it first."
        redirect_to :back
      end
    end

    def scoped_collection
      end_of_association_chain.includes(:user, :last_import_trail)
    end
  end

  index download_links: [:csv] do
    column :id
    column :user, sortable: :user_id
    column 'Scheduling Status' do |job|
      case
      when job.loading?
        status_tag('Loading', :yes)
      when job.process_running?
        status_tag('Running', :ok)
      when job.active?
        tz = (job.tz == 'UTC' || job.tz.blank?) ? job.tz : Time.now.in_time_zone(job.tz).strftime('%:::z')
        status_tag(:no, :no, label: "Each #{job.frequency_quantity} #{job.frequency_unit} at #{job.at} #{tz}")
      else
        status_tag('Inactive', :error)
      end
    end
    column :import_type
    column :last_ran_at, sortable: :last_ran_at do |import|
      import.last_ran_at.blank? ? "never" : l(import.last_ran_at, format: :long)
    end
    column :last_log do |import|
      link_to('view log', admin_import_trail_path(import.last_import_trail)) if import.last_import_trail
    end
    column :last_error, sortable: 'import_trails.error_msg' do |import|
      if (trail = import.last_import_trail)
        status_tag(trail.error_msg, :red) if trail.error_msg
        status_tag(trail.warning_msg, :orange) if trail.warning_msg
      end
    end
    column :last_duration do |import|
      import.last_import_trail.duration.strftime('%H:%M:%S') if import.last_import_trail.try(:finished_at)
    end

    actions do |job|
      if job.process_running?
        item 'Stop', stop_admin_import_path(job), method: :post, class: 'job-action job-action-danger'
      elsif job.active? && job.valid?
        item 'Run', run_admin_import_path(job), method: :post, class: 'job-action'
      end
    end
  end

  form partial: 'form'

  member_action :run, method: :post do
    resource.run!
    redirect_to :back
  end

  member_action :stop, method: :post do
    resource.stop!
    redirect_to :back
  end

  csv do
    column :user do |import|
      import.user.name
    end
    column :country do |import|
      import.user.country.try(&:name)
    end
    column :active
    column :import_type
    column :last_ran_at do |import|
      import.last_ran_at.blank? ? "never" : l(import.last_ran_at, format: :long)
    end
    column :created_at
    column :updated_at
  end

end
