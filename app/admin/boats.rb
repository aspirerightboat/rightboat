ActiveAdmin.register Boat do
  permit_params :manufacturer_id, :model_id, :price, :currency_id, :year_built,
                :featured, :recently_reduced, :under_offer, :new_boat,
                :fuel_type_id, :boat_type_id, :drive_type_id, :location, :country_id

  menu priority: 2

  filter :user
  filter :country
  filter :manufacturer
  filter :model, collection: []

  index do
    column :id
    column :name
    column :manufacturer_model
    column :user
    column :geocoded do |boat|
      boat.geocoded? ? status_tag('Geocoded', :ok) : status_tag('Failed', :error)
    end
    actions do |boat|
      item "Statistics", statistics_admin_boat_path(boat)
    end
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

  member_action :statistics, method: :get do
    @boat = Boat.find(params[:id])
    @page_title = @boat.name
    @monthly = Rightboat::Statistics.monthly_boat_stats(@boat)
  end
end
