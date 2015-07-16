ActiveAdmin.register Import do
  permit_params :import_type, :active, :use_proxy,
                :frequency_unit, :frequency_quantity, :at,
                param: []

  menu priority: 3

  filter :user, collection: -> { User.companies }
  filter :active
  filter :last_ran_at

  controller do
    before_filter :check_running_job, only: [:edit, :update, :destroy]

    private

    def check_running_job
      if resource.running?
        flash[:warning] = "You can not manage this import since it's in running status. Please stop it first."
        redirect_to action: :index
      end
    end

    def scoped_collection
      end_of_association_chain.includes(:user)
    end
  end

  index download_links: [:csv] do
    column :id
    column :user, sortable: :user_id
    column :active
    column 'Sechuling Status' do |job|
      job.running? ? status_tag('Running', :ok) : status_tag(job.active? && job.valid? ? 'Waiting' : 'Inactive')
    end
    column :import_type
    column :last_ran_at, sortable: :last_ran_at do |import|
      import.last_ran_at.blank? ? "never" : l(import.last_ran_at, format: :long)
    end
    column :created_at
    column :updated_at
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
    redirect_to action: :index
  end

  member_action :stop, method: :post do
    resource.stop!
    redirect_to action: :index
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
