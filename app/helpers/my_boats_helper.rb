module MyBoatsHelper
  def m_ft_field(name, value, label, id = nil)
    render partial: 'broker_area/my_boats/m_ft_field', locals: {name: name, value: value, label_text: label, id: id}
  end

  def spec_m_ft_field(spec_name, label)
    m_ft_field("boat_specs[#{spec_name}]", @specs_hash[spec_name], label, spec_name)
  end

  def spec_unit_field(spec_name, label, units)
    value = @specs_hash[spec_name]
    amount, unit = (value.split(' ', 2) if value)
    render partial: 'broker_area/my_boats/spec_unit_field',
           locals: {name: "boat_specs[#{spec_name}]",
                    value: value, amount: amount, selected_unit: unit,
                    label_text: label,
                    units: units}
  end

  def spec_checkable_field(spec_name, label = nil, options = {})
    label ||= spec_name.to_s.titleize
    opts = {id: spec_name, class: 'form-control', style: 'width: 200px; display: inline-block;'}.merge!(options)

    res = '<input type="checkbox">'.html_safe
    res << label_tag(spec_name, label)
    res << text_field_tag("boat_specs[#{spec_name}]", @specs_hash[spec_name], opts)
  end

  def spec_select_field(spec_name, label, units)
    # value = @boat_spec_by_name[spec_name].value.to_s
    # amount, unit = value.split(' ', 2)
    # render partial: 'broker_area/my_boats/spec_unit_field',
    #        locals: {name: "boat_specs[#{spec_name}]",
    #                 value: value, amount: amount, selected_unit: unit,
    #                 label_text: label,
    #                 units: units}
  end
end
