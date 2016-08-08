module SearchFormHelper
  def manufacturers_picker_field(name, manufacturer_ids = nil, field_id = nil)
    manufacturer_ids = manufacturer_ids.split('-') if manufacturer_ids&.is_a?(String)
    selected_manufacturer_infos = (Manufacturer.where(id: manufacturer_ids).pluck(:id, :name) if manufacturer_ids)
    popular_manufacturer_infos = Rails.cache.fetch 'top-30-maker-infos', expires_in: 1.day do
      Manufacturer.joins(:boats)
          .group('manufacturers.id, manufacturers.name').order('COUNT(*) DESC')
          .limit(30).pluck('manufacturers.id, manufacturers.name')
    end
    initial_options = popular_manufacturer_infos.tap do |arr|
      selected_manufacturer_infos&.each { |id, m_name| arr << [id, m_name] if !arr.find { |info| id == info[0] } }
    end.sort_by(&:second).map { |id, m_name| {id: id, name: m_name} }

    text_field_tag name, manufacturer_ids&.join('-'), id: field_id || 'manufacturers_picker',
                   data: {collection: 'manufacturers', 'initial-options' => initial_options.to_json},
                   class: 'select-black tags-input manufacturers-picker', placeholder: 'e.g. Beneteau'
  end

  def models_picker_field(name, model_ids = nil, field_id = nil)
    model_ids = model_ids.split('-') if model_ids&.is_a?(String)
    models = (Model.where(id: model_ids).pluck_h(:id, :name) if model_ids)

    text_field_tag name, model_ids&.join('-'), id: field_id || 'models_picker',
                   data: {'initial-options' => models&.to_json, collection: 'models'},
                   class: 'select-black tags-input models-picker', placeholder: 'e.g. Oceanis 34'
  end
end
