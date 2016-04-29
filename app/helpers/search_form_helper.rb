module SearchFormHelper
  def manufacturers_picker_field(name, manufacturer_ids = nil, field_id = nil)
    manufacturer_ids = manufacturer_ids.split('-') if manufacturer_ids&.is_a?(String)
    manufacturers = (Manufacturer.where(id: manufacturer_ids).pluck(:id, :name) if manufacturer_ids)

    text_field_tag name, manufacturer_ids&.join('-'), id: field_id || 'manufacturers_picker',
                   data: {initial_tags: manufacturers&.to_json, collection: 'manufacturers'},
                   class: 'select-black select-full tags-input manufacturers-picker', placeholder: 'e.g. Beneteau'
  end

  def models_picker_field(name, model_ids = nil, field_id = nil)
    model_ids = model_ids.split('-') if model_ids&.is_a?(String)
    models = (Model.where(id: model_ids).pluck(:id, :name) if model_ids)

    text_field_tag name, model_ids&.join('-'), id: field_id || 'models_picker',
                   data: {initial_tags: models&.to_json, collection: 'models'},
                   class: 'select-black select-full tags-input models-picker', placeholder: 'e.g. Oceanis 34'
  end
end