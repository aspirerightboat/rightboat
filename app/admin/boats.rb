ActiveAdmin.register Boat do
  permit_params :manufacturer_id, :model_id, :price, :currency_id, :year_built,
                :featured, :recently_reduced, :under_offer, :new_boat, :description,
                :fuel_type_id, :boat_type_id, :drive_type_id, :location, :country_id

  menu priority: 2

  filter :name_or_manufacturer_name_or_model_name_or_office_name_cont, as: :string, label: 'Name | Manuf | Model | Office'
  filter :id
  filter :user, as: :select, collection: User.companies.order(:company_name)
  filter :country, as: :select, collection: Country.order(:name)
  filter :manufacturer, as: :select, collection: Manufacturer.order(:name)
  filter :model, collection: []
  filter :featured
  filter :recently_reduced
  filter :under_offer
  filter :new_boat, label: 'New/Used', as: :select, collection: [['New', true], ['Used', false]]
  filter :boat_type_name, label: 'Boat Type', as: :select, collection: BoatType::GENERAL_TYPES

  index do
    column :id
    column :images do |boat|
      if boat.primary_image
        img = image_tag(boat.primary_image.file.url(:mini), size: '64x43')
      else
        img = content_tag(:div, nil, style: 'background-color: lightgray; width: 64px; height: 43px;')
      end
      link_to(img, admin_boat_images_path(q: {boat_id_equals: boat.id}))
    end
    column 'Imgs' do |boat|
      boat.boat_images.count
    end
    column :name
    column :manufacturer, :manufacturer, sortable: 'manufacturers.name'
    column :model, :model, sortable: 'models.name'
    column :status do |boat|
      # boat.deleted? ? 'Inactive' : 'Active'
      boat.live? ? 'Active' : 'Inactive'
    end
    column :user, :user, sortable: 'users.first_name'
    column :office, :office, sortable: 'offices.name'
    column :location do |boat|
      res = []
      res << link_to(boat.country.name, admin_country_path(boat.country)) if boat.country
      res << html_escape(boat.location) if boat.location.present?
      res << content_tag(:span, "#{'Not ' if !boat.geocoded?}Geocoded", class: "status_tag #{boat.geocoded? ? 'ok' : 'no'}")
      res.join('<br>').html_safe
    end
    actions do |boat|
      item 'Stats', statistics_admin_boat_path(boat), class: 'member_link'
      item boat.deleted? ? 'Activate' : 'Deactivate', toggle_active_admin_boat_path(boat.slug), class: 'member_link'
    end
  end

  index as: :grid do |boat|
    link_to image_tag(boat.primary_image.file.url(:thumb)), admin_boat_path(boat)
  end

  form do |f|
    f.inputs do
      f.input :manufacturer, include_blank: false
      f.input :model, collection: [f.object.model], include_blank: false
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
      Boat.includes(:manufacturer, :user, :country, :office, :primary_image, :model)
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
    link_to('Delete images', {action: :delete_images}, method: :post, confirm: 'Are you sure?', disable_with: 'Deleting...') if boat.boat_images.any?
    link_to 'Manage images', admin_boat_images_path(q: {boat_id_equals: boat.id}) if boat.boat_images.any?
  end

  member_action :statistics, method: :get do
    @boat = Boat.find_by(slug: params[:id])
    @page_title = @boat.name
    @monthly = Rightboat::Statistics.monthly_boat_stats(@boat)
  end

  member_action :toggle_active, method: :get do
    boat = Boat.find_by(slug: params[:id])
    activate = boat.deleted?
    activate ? boat.revive : boat.destroy

    redirect_to (request.referer || {action: :index}), notice: "boat #{boat.slug} was #{activate ? 'activated' : 'deactivated'}"
  end

  member_action :delete_images, method: :post do
    boat = Boat.find_by(slug: params[:id])
    boat.boat_images.destroy_all

    redirect_to (request.referer || {action: :index}), notice: "Images was deleted for boat #{boat.slug}"
  end

  collection_action :delete_all_boats, method: :post do
    if !Rails.env.production?
      Boat.each do |boat|
        boat.destroy(:force)
      end
      flash.notice = 'All the boats were deleted'
    end
    redirect_to(action: :index)
  end

  collection_action :activate_all_models, method: :post do
    Boat.update_all(deleted_at: nil); Boat.reindex
    Import.update_all(active: true)
    Sunspot.commit

    redirect_to({action: :index}, {notice: 'All models was activated'})
  end
end
