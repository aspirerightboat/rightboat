ActiveAdmin.register Misspelling do
  controller do
    belongs_to :manufacturer, polymorphic: true, optional: true
    belongs_to :country, polymorphic: true, optional: true
    belongs_to :specification, polymorphic: true, optional: true
    belongs_to :model, polymorphic: true, optional: true
    belongs_to :engine_manufacturer, polymorphic: true, optional: true
    belongs_to :engine_model, polymorphic: true, optional: true
    belongs_to :vat_rate, polymorphic: true, optional: true
  end

  config.sort_order = 'alias_string_asc'
  menu priority: 10

  permit_params :alias_string, :source_type, :source_id

  filter :alias_string, label: 'From'
  filter :source_type, label: 'Field'

  index do
    column 'From', :alias_string
    column 'Field', :source_type
    column 'To', :source
    actions
  end

  form do |f|
    f.inputs do
      f.input :alias_string, label: 'From'
      f.input :source_type, as: :select, label: 'Field', collection: %w(Manufacturer Model Country Specification EngineManufacturer EngineModel VatRate), include_blank: false
      f.input :source_id, as: :hidden
      f.input :source_name, as: :autocomplete, url: search_admin_manufacturers_path, label: 'To', input_html: { id_element: '#misspelling_source_id' }
    end
    f.actions
  end

end
