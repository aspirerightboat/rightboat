ActiveAdmin.register Boat, as: 'Featured Boats' do

	menu parent: 'Boats', priority: 21
  actions :index

  filter :name_or_manufacturer_name_or_model_name_or_office_name_cont, as: :string, label: 'Name | Manuf | Model | Office'
  filter :id
  filter :user, as: :select, collection: User.companies
  filter :country, as: :select, collection: Country.order(:name)
  filter :manufacturer_name_cont
  filter :model_name_cont
  filter :status, as: :select, collection: Boat.statuses
  filter :offer_status, as: :select, collection: Boat::OFFER_STATUSES
  filter :new_boat, label: 'New/Used', as: :select, collection: [['New', true], ['Used', false]]
  filter :boat_type_name_stripped, label: 'Boat Type', as: :select, collection: BoatType::GENERAL_TYPES

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
    column :status
    column :user, :user, sortable: 'users.first_name'
    column :office, :office, sortable: 'offices.name'
    column(:location) { |boat| boat_location_column(boat) }
    actions do |boat|
      item 'Unfavourite', admin_boat_path(boat, boat: { featured: false }), method: :put, class: 'member_link'
    end
  end

  controller do
    def scoped_collection
      end_of_association_chain.featured.includes(:manufacturer, :user, :country, :office, :primary_image, :model)
    end
  end
end
