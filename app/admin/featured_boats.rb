ActiveAdmin.register Boat, as: 'Featured Boats' do

	menu parent: 'Boats', priority: 21
  actions :index

  filter :name_or_manufacturer_name_or_model_name_or_office_name_cont, as: :string, label: 'Name | Manuf | Model | Office'
  filter :id
  filter :user, as: :select, collection: User.companies.order(:company_name)
  filter :country, as: :select, collection: Country.order(:name)
  filter :manufacturer_name_cont
  filter :model_name_cont
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
      item 'Deactivate', admin_boat_path(boat, boat: { featured: false }), method: :put, class: 'member_link'
    end
  end

  controller do
    def scoped_collection
      end_of_association_chain.featured.includes(:manufacturer, :user, :country, :office, :primary_image, :model)
    end
  end
end