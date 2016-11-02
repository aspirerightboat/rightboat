ActiveAdmin.register User, as: 'BrokerInventroyTrends' do
  menu parent: 'Boats', priority: 13

  actions :all, except: [:new, :create, :show, :edit, :update, :destroy]

  filter :id, as: :select, collection: User.companies.order(:company_name), label: 'User'
  filter :created_at, label: 'Start / End date'

  controller do
    def index
      @page_title = 'Inventory Trends'
      super
    end

    protected

    def scoped_collection
      params[:q] ||= {}
      params[:q][:created_at_gteq_date] ||= 1.months.ago.to_date.to_s
      params[:q][:created_at_lteq_date] ||= Date.today.to_s

      User.companies.
            select('users.id, users.company_name').
            select(
              "IFNULL((SELECT SUM("\
              "IFNULL((SELECT import_trails.boats_count "\
              "FROM import_trails "\
              "WHERE import_trails.import_id = imports.id "\
              "AND DATE(import_trails.created_at) = '#{params[:q][:created_at_gteq_date]}' "\
              "ORDER BY import_trails.created_at DESC "\
              "LIMIT 1), 0)) AS import_start_count "\
              "FROM imports WHERE imports.user_id = users.id), 0) "\
              "AS start_count").
            select(
              "IFNULL((SELECT SUM("\
              "IFNULL((SELECT import_trails.boats_count "\
              "FROM import_trails "\
              "WHERE import_trails.import_id = imports.id "\
              "AND DATE(import_trails.created_at) = '#{params[:q][:created_at_lteq_date]}' "\
              "ORDER BY import_trails.created_at DESC "\
              "LIMIT 1), 0)) AS import_start_count "\
              "FROM imports WHERE imports.user_id = users.id), 0) "\
              "AS end_count")
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
    h3 class: 'text-center' do
      "#{date_format(params[:q][:created_at_gteq_date])} ~ #{date_format(params[:q][:created_at_lteq_date])}"
    end

    column :user, sortable: 'users.company_name' do |user|
      link_to(user.company_name, admin_user_path(user.id))
    end
    column :start_count, sortable: 'start_count' do |user|
      user.start_count
    end
    column :end_count, sortable: 'end_count' do |user|
      user.end_count
    end
    column :delta, sortable: 'delta' do |user|
      user.end_count - user.start_count
    end
  end

  csv do
    column :user do |user|
      user.company_name
    end
    column :start_count do |user|
      user.start_count
    end
    column :end_count do |user|
      user.end_count
    end
    column :delta do |user|
      user.end_count - user.start_count
    end
  end
end
