ActiveAdmin.register Boat do
  permit_params :manufacturer_id, :model_id, :price, :currency_id, :year_built, :poa,
                :featured, :recently_reduced, :offer_status, :new_boat, :description, :short_description,
                :fuel_type_id, :boat_type_id, :drive_type_id, :location, :country_id

  menu priority: 2

  filter :name_or_manufacturer_name_or_model_name_or_office_name_cont, as: :string, label: 'Name | Manuf | Model | Office'
  filter :id
  filter :user, as: :select, collection: User.companies.order(:company_name)
  filter :country, as: :select, collection: Country.order(:name)
  filter :manufacturer_name_cont
  filter :model_name_cont
  filter :featured
  filter :recently_reduced
  filter :offer_status, as: :select, collection: Boat::OFFER_STATUSES
  filter :new_boat, label: 'New/Used', as: :select, collection: [['New', true], ['Used', false]]
  filter :boat_type_name, label: 'Boat Type', as: :select, collection: BoatType::GENERAL_TYPES

  index do
    selectable_column
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
      item boat.deleted? ? 'Activate' : 'Deactivate', toggle_active_admin_boat_path(boat.slug), class: 'member_link', method: :post
      item 'PDF', boat_pdf_path(boat), target: '_blank', class: 'member_link'
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
      f.input :short_description
      f.input :description
      f.input :boat_type
      f.input :fuel_type
      f.input :drive_type
      f.input :location
      f.input :country, as: :select, collection: Country.order(:name)
      f.input :offer_status, as: :select, collection: Boat::OFFER_STATUSES
      f.input :featured, as: :boolean
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

  sidebar 'Tools', only: [:show, :edit] do
    img_cnt = boat.boat_images.not_deleted.count
    s = ''
    s << "<p>Images count: <b>#{img_cnt}</b></p>"
    if boat.boat_images.any?
      s << '<p>'
      s << link_to('Manage images', admin_boat_images_path(q: {boat_id_equals: boat.id}))
      s << '</p><p>'
      s << link_to('Delete images', {action: :delete_images}, method: :post, class: 'button',
                   data: {confirm: 'Are you sure?', disable_with: 'Working...'})
      s << link_to(boat.deleted? ? 'Activate' : 'Deactivate', toggle_active_admin_boat_path(boat), method: :post, class: 'button',
                   data: {confirm: 'Are you sure?', disable_with: 'Working...'})
      s << '</p>'
    end
    s.html_safe
  end

  sidebar 'Tools', only: [:index] do
    content_tag(:p, link_to('Reindex deleted boats', {action: :reindex_deleted_boats}, method: :post, class: 'button'))
  end

  collection_action :reindex_deleted_boats, method: :post do
    search = Boat.solr_search do
      with :live, true
      paginate page: 1, per_page: Boat.count
    end
    live_boats = search.results
    fix_boats = live_boats.select { |b| b.deleted? }
    Sunspot.index! fix_boats if fix_boats.any?
    redirect_to (request.referer || {action: :index}),
                notice: "Found #{live_boats.size} live boats and #{fix_boats.size} of them are actually deleted. Reindex these boats"
  end

  member_action :statistics, method: :get do
    @boat = Boat.find_by(slug: params[:id])
    @page_title = @boat.name
    @monthly = Rightboat::Statistics.monthly_boat_stats(@boat)
  end

  member_action :toggle_active, method: :post do
    boat = Boat.find_by(slug: params[:id])
    if (activate = boat.deleted?)
      boat.revive
      boat.user.increment(:boats_count)
    else
      boat.destroy
    end

    redirect_to (request.referer || {action: :index}), notice: "boat id=#{boat.id} was #{activate ? 'activated' : 'deactivated'}"
  end

  member_action :delete_images, method: :post do
    boat = Boat.find_by(slug: params[:id])
    cnt = boat.boat_images.destroy_all.size

    redirect_to (request.referer || {action: :index}), notice: "#{cnt} images was deleted for boat id=#{boat.id}"
  end

  batch_action :delete_images do |ids|
    cnt = 0
    Boat.includes(:boat_images).find(ids).each do |b|
      cnt += b.boat_images.destroy_all.size
    end
    redirect_to collection_path, notice: "#{cnt} boat images was deleted"
  end

end
