ActiveAdmin.register Export do
  menu priority: 4

  filter :id, as: :numeric
  filter :user, collection: -> { User.companies }
  filter :active
  filter :export_type, as: :select, collection: -> { Export.export_types }
  filter :started_at
  filter :error_msg_cont

  controller do
    private

    def scoped_collection
      end_of_association_chain.includes(:user)
    end
  end

  index do
    column :id
    column :user
    column :export_type
    column :started_at
    column :last_duration do |export|
      export.duration.try(:strftime, '%H:%M:%S')
    end
    column :last_error do |export|
      status_tag(export.error_msg, :red) if export.error_msg
    end
    column :last_log do |export|
      link_to 'view log', [:last_log, :admin, export]
    end
    column :feed_link do |export|
      link_to 'feed', export.feed_public_path, target: '_blank'
    end
    actions do |export|
      item 'Run', [:run, :admin, export], method: :post, class: 'job-action', data: {disable_with: 'Working...'}
    end
  end

  sidebar 'Tools', only: [:index, :last_log] do
    para { link_to 'Run All', [:run_all, :admin, :exports], method: :post, class: 'button', data: {disable_with: 'Working...'} }
  end

  member_action :run, method: :post do
    system "bundle exec rake export:run[#{resource.id}] &"
    redirect_to :back
  end

  collection_action :run_all, method: :post do
    system 'bundle exec rake export:run_all &'
    redirect_to({action: :index})
  end

  member_action :last_log do
  end

end
