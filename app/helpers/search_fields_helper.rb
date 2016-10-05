module SearchFieldsHelper
  def boat_type_radio_buttons(boat_type, id_prefix:, name_prefix: nil, class_name: nil)
    name = name_prefix ? "#{name_prefix}[boat_type]" : 'boat_type'
    content_tag(:div, class: "radio-buttons #{class_name}".strip) do
      s = radio_button_tag(name, '', boat_type.blank?, id: "#{id_prefix}_boat_type_all")
      s << label_tag("#{id_prefix}_boat_type_all", 'All')
      s << radio_button_tag(name, 'power', boat_type == 'power', id: "#{id_prefix}_boat_type_power")
      s << label_tag("#{id_prefix}_boat_type_power", 'Power')
      s << radio_button_tag(name, 'sail', boat_type == 'sail', id: "#{id_prefix}_boat_type_sail")
      s << label_tag("#{id_prefix}_boat_type_sail", 'Sail')
    end
  end

  def new_used_checkboxes(new_used, id_prefix:, name_prefix: nil, class_name: nil)
    name_start = name_prefix ? "#{name_prefix}[new_used]" : 'new_used'
    content_tag :div, class: class_name do
      s = check_box_tag("#{name_start}[new]", true, new_used&.dig('new'), id: "#{id_prefix}_new_used_new")
      s << label_tag("#{id_prefix}_new_used_new", 'New')
      s << check_box_tag("#{name_start}[used]", true, new_used&.dig('used'), id: "#{id_prefix}_new_used_used")
      s << label_tag("#{id_prefix}_new_used_used", 'Used')
    end
  end

  def tax_status_checkboxes(tax_status, id_prefix:, name_prefix: nil, class_name: nil)
    name_start = name_prefix ? "#{name_prefix}[tax_status]" : 'tax_status'
    content_tag :div, class: class_name do
      s = check_box_tag("#{name_start}[paid]", true, tax_status&.dig('paid'), id: "#{id_prefix}_tax_status_paid")
      s << label_tag("#{id_prefix}_tax_status_paid", 'Paid')
      s << check_box_tag("#{name_start}[unpaid]", true, tax_status&.dig('unpaid'), id: "#{id_prefix}_tax_status_unpaid")
      s << label_tag("#{id_prefix}_tax_status_unpaid", 'Unpaid')
    end
  end
end
