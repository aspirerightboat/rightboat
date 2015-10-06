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
    column :status do |boat|
      # boat.deleted? ? 'Inactive' : 'Active'
      boat.live? ? 'Active' : 'Inactive'
    end
    column :user, :user, sortable: 'users.first_name'
    column :office, :office, sortable: 'offices.name'
    column :geocoded do |boat|
      boat.geocoded? ? status_tag('Geocoded', :ok) : status_tag('Failed', :error)
    end
    column :country, :country, sortable: 'countries.name'
    column :location
    column :images do |boat|
      boat.boat_images.count
    end
    actions do |boat|
      item 'Statistics', statistics_admin_boat_path(boat), class: 'member_link'
      item boat.deleted? ? 'Activate' : 'Deactivate', toggle_active_admin_boat_path(boat.slug), class: 'member_link'
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
      f.input :country, as: :select, collection: Country.order(:name)
      f.input :featured, as: :boolean
      f.input :under_offer, as: :boolean
      f.input :recently_reduced, as: :boolean
    end
    actions
  end

  controller do
    def scoped_collection
      Boat.includes(:manufacturer, :user, :country, :office, :boat_images, model: :manufacturer)
    end

    def find_resource
      Boat.find(params[:id])
    end
  end

  if !Rails.env.production?
    sidebar 'Tools', only: [:index] do
      res = link_to('Delete All Boats', {action: :delete_all_boats}, method: :post, class: 'button', style: 'margin-bottom: 10px',
              data: {confirm: 'Are you sure you want to delete all boat data?', disable_with: 'Deleting...'})
      res << link_to('Activate All Models', {action: :activate_all_models}, method: :post, class: 'button')
      res
    end
  end

  sidebar 'Tools', only: [:show, :edit] do
    link_to boat.deleted? ? 'Activate' : 'Deactivate', toggle_active_admin_boat_path(boat)
  end

  member_action :statistics, method: :get do
    @boat = Boat.find_by(slug: params[:id])
    @page_title = @boat.name
    @monthly = Rightboat::Statistics.monthly_boat_stats(@boat)
  end

  member_action :toggle_active, method: :get do
    boat = Boat.find_by(slug: params[:id])
    active = boat.deleted_at.present?
    boat.deleted_at = active ? nil : Time.current
    boat.save!
    redirect_to (request.referer || {action: :index}), notice: "boat #{boat.slug} was #{active ? 'activated' : 'deactivated'}"
  end

  collection_action :delete_all_boats, method: :post do
    if !Rails.env.production?
      Boat.each do |boat|
        boat.destroy
      end
      flash.notice = 'All the boats were deleted'
    end
    redirect_to(action: :index)
  end

  collection_action :activate_all_models, method: :post do
    Boat.update_all(deleted_at: nil); Boat.reindex
    BoatCategory.update_all(active: true); BoatCategory.reindex
    BoatType.update_all(active: true); BoatType.reindex
    Country.update_all(active: true); Country.reindex
    Currency.update_all(active: true)
    DriveType.update_all(active: true)
    EngineManufacturer.update_all(active: true)
    EngineModel.update_all(active: true)
    FuelType.update_all(active: true); FuelType.reindex
    Import.update_all(active: true)
    Manufacturer.update_all(active: true); Manufacturer.reindex
    Model.update_all(active: true); Model.reindex
    Specification.update_all(active: true)
    VatRate.update_all(active: true)
    Sunspot.commit

    redirect_to({action: :index}, {notice: 'All models was activated'})
  end
end
