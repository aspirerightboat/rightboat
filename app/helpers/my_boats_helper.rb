module MyBoatsHelper
  def m_ft_field(name, value, label, id = nil, options = {})
    render partial: 'broker_area/my_boats/m_ft_field', locals: {name: name, value: value, label_text: label, id: id, options: options}
  end

  def spec_m_ft_field(spec_name, label, options = {})
    m_ft_field("boat_specs[#{spec_name}]", @specs_hash.delete(spec_name), label, spec_name, options)
  end

  def spec_unit_field(spec_name, label, units, options = {})
    value = @specs_hash.delete(spec_name)
    amount, unit = (value.split(' ', 2) if value)
    render partial: 'broker_area/my_boats/spec_unit_field',
           locals: {name: "boat_specs[#{spec_name}]",
                    value: value, amount: amount, selected_unit: unit,
                    label_text: label,
                    units: units,
                    options: options}
  end

  def spec_checkable_field(spec_name, label = nil, options = {})
    label ||= spec_name.to_s.titleize
    value = @specs_hash.delete(spec_name)
    opts = {id: spec_name, class: 'form-control', style: 'width: 200px; display: inline-block;'}.merge!(options)

    res = '<input type="checkbox">'.html_safe
    res << label_tag(spec_name, label)
    res << text_field_tag("boat_specs[#{spec_name}]", value, opts)
  end

  def ajax_collection_field(id, value, options = {})
    label = (options.delete(:label) || id.to_s).titleize
    res = label_tag(id, label, options.delete(:label_options) || {})

    name = options.delete(:name) || id
    opts = {placeholder: 'Please select...', id: id,
            class: 'collection-select select-dark inline-select', data: {collection: "#{id}s", create: true},
            style: 'width: 200px'}.deep_merge!(options)

    res << text_field_tag(name, value, opts)
  end

  def spec_ajax_collection_field(id, options = {})
    value = @specs_hash.delete(id)
    options[:name] = "boat_specs[#{id}]"
    ajax_collection_field(id, value, options)
  end

  def spec_number_field(spec_name, label = nil, options = {})
    spec_common_field(spec_name, label, options.merge!(field_type: :number))
  end

  def spec_text_field(spec_name, label = nil, options = {})
    spec_common_field(spec_name, label, options.merge!(field_type: :text))
  end

  def spec_textarea_field(spec_name, label = nil, options = {})
    spec_common_field(spec_name, label, options.merge!(field_type: :textarea))
  end

  def spec_common_field(spec_name, label = nil, options = {})
    label ||= spec_name.to_s.titleize
    res = label_tag(spec_name, label, options.delete(:label_options) || {})

    name = "boat_specs[#{spec_name}]"
    value = @specs_hash.delete(spec_name)
    field_method = case options.delete(:field_type)
                   when :text then :text_field_tag
                   when :number then :number_field_tag
                   when :textarea then :text_area_tag
                   end
    opts = {id: spec_name, class: 'form-control', style: 'width: 120px; display: inline-block;'}.deep_merge!(options)
    res << send(field_method, name, value, opts)
  end
end
