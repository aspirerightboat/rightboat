ActiveAdmin.register Boat do
  permit_params :manufacturer_id, :model_id, :price, :currency_id, :year_built, :poa,
                :featured, :recently_reduced, :offer_status, :new_boat,
                :fuel_type_id, :boat_type_id, :drive_type_id, :location, :country_id, :slug,
                extra_attributes: [:id, :description, :short_description, :owners_comment, :disclaimer]

  menu priority: 2

  filter :name_or_manufacturer_name_or_model_name_or_office_name_cont, as: :string, label: 'Name | Makemodel | Office'
  filter :id
  filter :user, as: :select, collection: User.companies.order(:company_name)
  filter :country, as: :select, collection: Country.order(:name)
  filter :manufacturer_name_cont, label: 'Manufacturer Name Contains'
  filter :model_name_cont, label: 'Model Name Contains'
  filter :status, as: :select, collection: Boat.statuses
  filter :featured
  filter :recently_reduced
  filter :offer_status, as: :select, collection: Boat::OFFER_STATUSES
  filter :new_boat, label: 'New/Used', as: :select, collection: [['New', true], ['Used', false]]
  filter :boat_type_name, label: 'Boat Type', as: :select, collection: BoatType::GENERAL_TYPES
  filter :deleted_at_present, as: :boolean, label: 'Deleted'

  index do
    selectable_column
    column(:id) { |boat| "#{boat.id} (#{boat.ref_no})" }
    column :images do |boat|
      if boat.primary_image
        img = image_tag(boat.primary_image.file.url(:mini), size: '64x43')
      else
        img = content_tag(:div, nil, style: 'background-color: lightgray; width: 64px; height: 43px;')
      end
      link_to(img, admin_boat_images_path(q: {boat_id_equals: boat.id}))
    end
    column('Imgs') { |boat| boat.boat_images.not_deleted.count }
    column('Name/Makemodel') do |boat|
      [html_escape(boat.name),
       link_to(boat.manufacturer.name, admin_manufacturer_path(boat.manufacturer)),
       link_to(boat.model.name, admin_model_path(boat.model))].reject(&:blank?).join('<br>').html_safe
    end
    column(:price) { |boat| number_to_currency(boat.price, unit: boat.safe_currency.symbol, precision: 0) }
    column(:status) { |boat| boat.inactive? ? "inactive: #{boat.inactive_reason}" : boat.status }
    column :user, :user, sortable: 'users.company_name'
    column :office, :office, sortable: 'offices.name'
    column(:location) { |boat| boat_location_column(boat) }
    actions do |boat|
      item 'Stats', statistics_admin_boat_path(boat), class: 'member_link'
      item boat.deleted? ? 'Activate' : 'Deactivate', toggle_active_admin_boat_path(boat.slug), class: 'member_link', method: :post
      item 'PDF', makemodel_boat_pdf_path(boat), target: '_blank', class: 'member_link' if boat.active? && !boat.deleted?
    end
  end

  index as: :grid do |boat|
    link_to image_tag(boat.primary_image.file.url(:thumb)), admin_boat_path(boat)
  end

  show do |boat|
    default_main_content
    panel 'Extra Information' do
      attributes_table_for resource.extra do
        (BoatExtra.column_names - %w(id boat_id deleted_at updated_at created_at)).each { |col| row col }
      end
    end
    panel 'Specifications' do
      table_for boat.boat_specifications.not_deleted.includes(:specification) do
        column :name do |bs|
          bs.specification.display_name
        end
        column :value
      end
    end
    if boat.class_groups.any?
      panel 'Boat Class Groups' do
        table_for boat.class_groups.not_deleted.includes(:class_code) do
          column :class_code do |cg|
            cg.class_code.name
          end
          column :primary do |cg|
            cg.primary
          end
        end
      end
    end
    if boat.media.any?
      panel 'Boat Additional Media' do
        table_for boat.media.not_deleted do
          column :source_url do |bm|
            bm.source_url
          end
          column :title do |bm|
            bm.attachment_title
          end
          column :alternate_text do |bm|
            bm.alternate_text
          end
          column :type do |bm|
            bm.type_string
          end
        end
      end
    end
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
      f.input :boat_type
      f.input :fuel_type
      f.input :drive_type
      f.input :location
      f.input :country, as: :select, collection: Country.order(:name)
      f.input :offer_status, as: :select, collection: Boat::OFFER_STATUSES
      f.input :featured, as: :boolean
      f.input :recently_reduced, as: :boolean
      f.input :slug

      f.has_many :extra, allow_destroy: false, new_record: f.object.extra.blank? do |ff|
        ff.input :short_description
        ff.input :description
        ff.input :owners_comment
        ff.input :disclaimer
      end
    end
    actions
  end

  csv do
    column :id
    column(:images) { |boat| boat.primary_image&.file&.url(:mini) }
    column('Imgs') { |boat| boat.boat_images.not_deleted.count }
    column :name
    column :manufacturer
    column :model
    column :boat_type
    column :category
    column :price
    column(:currency) { |boat| boat.currency&.name }
    column :status
    column :user
    column(:office) { |boat| boat.office&.name }
    column(:country) { |boat| boat.country&.name }
    column(:location) { |boat| boat.location }
  end

  controller do
    def scoped_collection
      # never add :primary_image - it breaks query for sorting
      end_of_association_chain.includes(:manufacturer, :user, :country, :office, :model, :currency)
    end

    def find_resource
      Boat.find_by(slug: params[:id]) || Boat.find(params[:id])
    end

    def destroy
      resource.update_column(:deleted_by_user_id, current_user.id)
      destroy! { request.referer || {action: :index} }
    end
  end

  sidebar 'Tools', only: [:show, :edit] do
    img_active_count = boat.boat_images.not_deleted.count
    img_hidden_count = boat.boat_images.deleted.count
    para {
      text_node "Active images count: <b>#{img_active_count}</b>".html_safe
      text_node "<br>Hidden images count: <b>#{img_hidden_count}</b>".html_safe if img_hidden_count > 0
    }

    if img_active_count > 0 || img_hidden_count > 0
      para { link_to 'Manage images', admin_boat_images_path(q: {boat_id_equals: boat.id}) }
      para { link_to 'Delete boat images', {action: :delete_images}, method: :post, class: 'button',
                     data: {confirm: 'Are you sure?', disable_with: 'Working...'} } if img_active_count > 0
    end

    para { link_to boat.deleted? ? 'Activate boat' : 'Deactivate boat', toggle_active_admin_boat_path(boat), method: :post, class: 'button',
                   data: {confirm: 'Are you sure?', disable_with: 'Working...'} }
  end

  sidebar 'Tools', only: [:index] do
    para { link_to 'Reindex deleted boats', {action: :reindex_deleted_boats}, method: :post, class: 'button', data: {disable_with: 'Working...'} }
    para { link_to 'Remove cached pdfs', {action: :remove_pdfs}, method: :post, class: 'button', data: {disable_with: 'Working...'} }
  end

  collection_action :reindex_deleted_boats, method: :post do
    search = Boat.retryable_solr_search! do
      with :live, true
      paginate page: 1, per_page: Boat.count
    end
    live_boats = search.results
    fix_boats = live_boats.select { |b| b.deleted? }
    Sunspot.index! fix_boats if fix_boats.any?
    redirect_to (request.referer || {action: :index}),
                notice: "Found #{live_boats.size} live boats and #{fix_boats.size} of them are actually deleted. Reindex these boats"
  end

  collection_action :remove_pdfs, method: :post do
    inner_dirs = Dir["#{Rails.root}/boat_pdfs/*"]
    FileUtils.rm_rf(inner_dirs) if inner_dirs.any?

    redirect_to (request.referer || {action: :index}),
                notice: "Removed #{inner_dirs.size} directories with cached pdf files"
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
      boat.update_column(:deleted_by_user_id, nil)
    else
      boat.update_column(:deleted_by_user_id, current_user.id)
      boat.destroy
    end

    redirect_to (request.referer || {action: :index}), notice: "boat id=#{boat.id} was #{activate ? 'activated' : 'deactivated'}"
  end

  member_action :delete_images, method: :post do
    boat = Boat.find_by(slug: params[:id])
    cnt = boat.boat_images.each { |bi| bi.destroy(:force) }.size

    redirect_to (request.referer || {action: :index}), notice: "#{cnt} images was deleted for boat id=#{boat.id}"
  end

  batch_action :delete_images do |ids|
    cnt = 0
    Boat.includes(:boat_images).find(ids).each do |b|
      cnt += b.boat_images.each { |bi| bi.destroy(:force) }.size
    end
    redirect_to collection_path, notice: "#{cnt} boat images was deleted"
  end

  batch_action :destroy do |ids|
    Boat.find(ids).each do |boat|
      boat.update_column(:deleted_by_user_id, current_user.id)
      boat.destroy!
    end

    redirect_to({action: :index}, notice: "Deleted these boat_ids=#{ids.join(',')}")
  end

end
