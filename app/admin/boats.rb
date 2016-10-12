ActiveAdmin.register Boat do
  permit_params :name, :manufacturer_id, :model_id, :price, :currency_id, :year_built, :poa,
                :featured, :recently_reduced, :offer_status, :new_boat, :length_m, :length_f,
                :fuel_type_id, :boat_type_id, :drive_type_id, :location, :geo_location, :state,
                :country_id, :slug, :office_id, :engine_manufacturer_id, :engine_model_id,
                :vat_rate_id, :category_id, :published, :expert_boat,
                extra_attributes: [:id, :description, :short_description, :owners_comment, :disclaimer]

  menu priority: 2

  filter :name_or_manufacturer_name_or_model_name_or_office_name_cont, as: :string, label: 'Name | Makemodel | Office'
  filter :id
  filter :user, as: :select, collection: User.companies.order(:company_name)
  filter :country, as: :select, collection: Country.order(:name)
  filter :manufacturer_name_cont, label: 'Manufacturer Name Contains'
  filter :model_name_cont, label: 'Model Name Contains'
  filter :import_import_type_eq, as: :select, collection: Rightboat::Imports::ImporterBase.import_types, label: 'Import Type'
  filter :status, as: :select, collection: Boat.statuses
  filter :featured
  filter :recently_reduced
  filter :offer_status, as: :select, collection: Boat::OFFER_STATUSES
  filter :new_boat, label: 'New/Used', as: :select, collection: [['New', true], ['Used', false]]
  filter :boat_type_name_stripped, label: 'Boat Type', as: :select, collection: BoatType::GENERAL_TYPES
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
    if boat.raw_boat
      attributes_table do
        Boat.column_names.each do |attr_name|
          if attr_name.in?(BoatOverridableFields::OVERRIDABLE_FIELDS)
            row attr_name do
              content = String.new.html_safe
              if boat.field_overridden?(attr_name)
                content << %(<del class="overridden">#{pretty_admin_field(boat.raw_boat, attr_name)}</del>).html_safe
              end
              content << pretty_admin_field(boat, attr_name)
            end
          else
            row attr_name
          end
        end
      end
    else
      default_main_content
    end
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
    override_opts = ->(attr_name) do
      v = f.object.imported_field_value(attr_name)
      input_html = {class: 'overridable-field',
                    'data-raw-value' => case v when TrueClass then 1 when FalseClass then 0 else v.to_s end}

      if attr_name.to_s.end_with?('_id')
        input_html['data-raw-text'] = v.present? ? f.object.imported_field_value(attr_name.to_s.chomp('_id'))&.name : ''
      end

      {input_html: input_html}
    end

    f.inputs do
      f.input :name, override_opts.call(:name)
      f.input :manufacturer_id, override_opts.call(:manufacturer_id).deep_merge(
          as: :string,
          input_html: {
              id: 'manufacturer_id',
              class: 'admin-collection-picker overridable-field', maxlength: nil,
              'data-collection' => 'manufacturers',
              'data-init-item-text' => f.object.manufacturer&.name.to_s,
              'data-onchange-clear' => '#model_id',
          })
      f.input :model_id, override_opts.call(:model_id).deep_merge(
          as: :string,
          input_html: {
              id: 'model_id',
              class: 'admin-collection-picker overridable-field', maxlength: nil,
              'data-collection' => 'models',
              'data-init-item-text' => f.object.model&.name.to_s,
              'data-include-param' => '#manufacturer_id',
          })
      f.input :length_m, override_opts.call(:length_m)
      f.input :length_f, override_opts.call(:length_f)
      f.input :price, override_opts.call(:price)
      f.input :poa, override_opts.call(:poa)
      f.input :currency, override_opts.call(:currency_id)
      f.input :new_boat, {as: :select, collection: [['New Boat', 1], ['Used Boat', 0]], include_blank: 'Select...'}.merge!(override_opts.call(:new_boat))
      vat_rates = VatRate.where('id < 3 OR id = ? OR id = ?', f.object.vat_rate_id, f.object.imported_field_value(:vat_rate_id))
      f.input :vat_rate, {collection: vat_rates, include_blank: 'Select...', }.merge!(override_opts.call(:vat_rate_id))
      f.input :year_built, override_opts.call(:year_built)
      f.input :boat_type, {include_blank: 'Select...'}.merge!(override_opts.call(:boat_type_id))
      f.input :fuel_type, {include_blank: 'Select...'}.merge!(override_opts.call(:fuel_type_id))
      f.input :drive_type, {include_blank: 'Select...'}.merge!(override_opts.call(:drive_type_id))
      # f.input :category, {include_blank: 'Select...'}.merge!(override_opts.call(:category_id))
      f.input :engine_manufacturer_id, override_opts.call(:engine_manufacturer_id).deep_merge(
          as: :string,
          input_html: {
              id: 'engine_manufacturer_id',
              class: 'admin-collection-picker overridable-field', maxlength: nil,
              'data-collection' => 'engine_manufacturers',
              'data-init-item-text' => f.object.engine_manufacturer&.name.to_s,
              'data-onchange-clear' => '#engine_model_id',
          })
      f.input :engine_model_id, override_opts.call(:engine_model_id).deep_merge(
          as: :string,
          input_html: {
              id: 'engine_model_id',
              class: 'admin-collection-picker overridable-field', maxlength: nil,
              'data-collection' => 'engine_models',
              'data-init-item-text' => f.object.engine_model&.name.to_s,
              'data-include-param' => '#engine_manufacturer_id',
          })
      f.input :location, override_opts.call(:location)
      f.input :geo_location, override_opts.call(:geo_location)
      f.input :state, override_opts.call(:state)
      f.input :country, {as: :select, collection: Country.order(:name)}.merge!(override_opts.call(:country_id))
      f.input :offer_status, {as: :select, collection: Boat::OFFER_STATUSES}.merge!(override_opts.call(:offer_status))
      f.input :office, {as: :select, collection: f.object.user.offices}.merge!(override_opts.call(:office_id))
      f.input :featured
      f.input :recently_reduced
      f.input :published
      f.input :expert_boat

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
      Boat.includes(raw_boat: [:manufacturer, :model, :currency, :boat_type, :fuel_type, :country])
          .find_by(slug: params[:id]) || Boat.find(params[:id])
    end

    def update(_options={}, &block)
      BoatOverridableFields::OVERRIDABLE_FIELDS.each do |attr_name|
        resource.override_imported_value(attr_name, params[attr_name])
      end

      super do |success, failure|
        block.call(success, failure) if block
        failure.html { render :edit }
      end
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
