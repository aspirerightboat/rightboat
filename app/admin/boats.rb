ActiveAdmin.register Boat do
  permit_params :manufacturer_id, :model_id, :price, :currency_id, :year_built,
                :featured, :recently_reduced, :under_offer, :new_boat,
                :fuel_type_id, :boat_type_id, :drive_type_id, :location, :country_id

  menu priority: 2

  filter :name_or_manufacturer_name_or_model_name_or_office_name_cont, as: :string, label: 'Free'
  filter :id
  filter :user
  filter :country, as: :select, collection: Country.order(:name)
  filter :manufacturer, as: :select, collection: Manufacturer.order(:name)
  filter :model, collection: []
  filter :featured
  filter :recently_reduced
  filter :under_offer
  filter :new_boat, label: 'New/Used', as: :select, collection: [['New', true], ['Used', false]]

  index do
    column :id
    column :name
    column :manufacturer, :manufacturer, sortable: 'manufacturers.name'
    column :model, :model, sortable: 'models.name'
    column :user, :user, sortable: 'users.first_name'
    column :office, :office, sortable: 'offices.name'
    column :geocoded do |boat|
      boat.geocoded? ? status_tag('Geocoded', :ok) : status_tag('Failed', :error)
    end
    column :country, :country, sortable: 'countries.name'
    column :location
    actions do |boat|
      item 'Statistics', statistics_admin_boat_path(boat)
    end
  end

  index as: :grid do |boat|
    link_to image_tag(boat.primary_image.file.url(:thumb)), admin_boat_path(boat)
  end

  form do |f|
    f.inputs do 
      f.input :manufacturer, include_blank: false
      f.input :model, collection: [], include_blank: false
      f.input :price
      f.input :poa
      f.input :currency
      f.input :new_boat, as: :boolean
      f.input :year_built
      f.input :description
      f.input :boat_type
      f.input :fuel_type
      f.input :drive_type
      f.input :location
      f.input :country
      f.input :featured, as: :boolean
      f.input :under_offer, as: :boolean
      f.input :recently_reduced, as: :boolean
    end
    actions
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes(:manufacturer, :model, :user, :country)
    end
  end

  if !Rails.env.production?
    sidebar 'Delete All Boats', only: [:index] do
      link_to 'Delete All', {action: :delete_all_boats}, method: :post, class: 'button',
              data: {confirm: 'Are you sure to delete all the boats?', disable_with: 'Deleting...'}
    end
  end

  member_action :statistics, method: :get do
    @boat = Boat.find(params[:id])
    @page_title = @boat.name
    @monthly = Rightboat::Statistics.monthly_boat_stats(@boat)
  end

  collection_action :delete_all_boats, method: :post do
    if !Rails.env.production?
      Boat.unscoped.each do |boat|
        boat.destroy
      end
      flash.notice = 'All the boats were deleted'
    end
    redirect_to({action: :index})
  end
end
