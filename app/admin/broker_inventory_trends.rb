ActiveAdmin.register Import, as: 'BrokerInventroyTrends' do
  menu parent: 'Boats', priority: 13

  actions :all, except: [:new, :create, :show, :edit, :update, :destroy]

  filter :user_id, as: :select, collection: User.companies.order(:company_name), label: 'User'
  filter :created_at, label: 'Start / End date'

  controller do

    protected

    def scoped_collection
      start_date = (params[:q] && params[:q][:created_at_gteq_date].presence) || Date.today.beginning_of_month.to_s
      end_date = (params[:q] && params[:q][:created_at_lteq_date].presence) || Date.today.to_s

      @imports = Import.joins(:user).
                    select('users.id AS user_id, users.company_name AS company_name').
                    select("IFNULL((
                            SELECT import_trails.boats_count
                            FROM import_trails
                            WHERE import_trails.import_id = imports.id
                            AND DATE(import_trails.created_at) = '#{start_date}'
                            LIMIT 1), 0) AS start_count").
                    select("IFNULL((
                            SELECT import_trails.boats_count
                            FROM import_trails
                            WHERE import_trails.import_id = imports.id
                            AND DATE(import_trails.created_at) = '#{end_date}'
                            LIMIT 1), 0) AS end_count")
    end

    def apply_sorting(chain)
      if params[:order] && params[:order] =~ /delta/
        chain.reorder("(end_count - start_count) #{params[:order].gsub('delta_', '')}")
      else
        super
      end
    end

    def clean_search_params
      q = params[:q] || {}
      q = q.to_unsafe_h if q.respond_to? :to_unsafe_h
      q.delete_if{ |key, value| key =~ /created_at/ || value.blank? }
    end
  end

  index do
    column :user, sortable: 'users.company_name' do |import|
      link_to(import.company_name, admin_user_path(import.user_id))
    end
    column :start_count, sortable: 'start_count' do |import|
      import.start_count
    end
    column :end_count, sortable: 'end_count' do |import|
      import.end_count
    end
    column :delta, sortable: 'delta' do |import|
      import.end_count - import.start_count
    end
  end

end
