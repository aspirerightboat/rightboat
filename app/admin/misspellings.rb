ActiveAdmin.register Misspelling do
  controller do
    belongs_to :manufacturer, polymorphic: true, optional: true
    belongs_to :country, polymorphic: true, optional: true
    belongs_to :specification, polymorphic: true, optional: true
    belongs_to :engine_manufacturer, polymorphic: true, optional: true
    belongs_to :engine_model, polymorphic: true, optional: true
    belongs_to :vat_rate, polymorphic: true, optional: true

    def scoped_collection
      rel = super

      if params[:maker_name]
        manufacturer = Manufacturer.find_by(name: params[:maker_name])
        params[:maker_id] = manufacturer ? manufacturer.id.to_s : '0'
      end

      if params[:maker_id] && params.dig(:q, :source_type_eq) == 'Model'
        rel = rel.includes(:model).references(:model).where(models: {manufacturer_id: params[:maker_id]})
      else
        rel = rel.includes(:source)
      end

      rel
    end
  end

  config.sort_order = 'alias_string_asc'
  menu priority: 35

  permit_params :alias_string, :source_type, :source_id

  filter :alias_string, label: 'From'
  filter :source_type, label: 'Field'
  filter :source_id_eq, label: 'To ID'

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

  sidebar 'Tools', only: [:index] do
    form_tag [:admin, :misspellings], method: :get, class: 'filter_form' do
      s = String.new
      s << hidden_field_tag('q[source_type_eq]', 'Model')
      s << content_tag(:div, class: 'filter_form_field filter_string') do
        ss = String.new
        ss << label_tag('maker_name', 'Manufacturer Name (Models only)')
        ss << text_field_tag('maker_name', params[:maker_name], id: 'maker_name')
        ss.html_safe
      end
      s << content_tag(:div, class: 'buttons') do
        submit_tag 'Filter'
      end
      s.html_safe
    end
  end

end
