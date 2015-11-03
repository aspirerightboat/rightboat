ActiveAdmin.register Import do
  menu priority: 3

  filter :user, collection: -> { User.companies }
  filter :active
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
    column :active
    column 'Scheduling Status' do |job|
      status = job.status
      case status
        when /running/i then status_tag(status, :ok)
        when /loading/i then status_tag(status, :yes)
        when /waiting/i then status_tag(status, :no)
        when /inactive/i then status_tag(status, :error)
      end
    end
    column :import_type
    column :last_ran_at, sortable: :last_ran_at do |import|
      import.last_ran_at.blank? ? "never" : l(import.last_ran_at, format: :long)
    end
    column :last_log do |import|
      link_to('view log', admin_import_trail_path(import.last_import_trail)) if import.last_import_trail
    end
    column :last_error do |import|
      if import.last_import_trail && import.last_import_trail.error_msg.present?
        status_tag(import.last_import_trail.error_msg, :red)
      end
    end
    column :last_duration do |import|
      import.last_import_trail.duration.strftime('%H:%M:%S') if import.last_import_trail.try(:finished_at)
    end

    actions do |job|
      if job.running?
        # only show Stop button when rake task gets started
        item 'Stop', stop_admin_import_path(job), method: :post, class: 'job-action job-action-danger' if job.running?(false)
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
