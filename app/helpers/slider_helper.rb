module SliderHelper

  def slider_tag(field, options = {})
    key_min = :"#{field}_min"
    key_max = :"#{field}_max"

    ret =  hidden_field_tag(key_min)
    ret << hidden_field_tag(key_max)
    ret << content_tag(:div, nil, {
        'data-input' => field,
        'data-min' => options[:min] || general_boat_stats.send(key_min),
        'data-max' => options[:max] || general_boat_stats.send(key_max),
        'data-value0' => params[key_min].presence,
        'data-value1' => params[key_max].presence,
        'data-unit' => options[:unit],
        class: "slider #{field}-slider #{options[:class]}".strip
    })
    ret << content_tag(:div, class: 'slider-label') do
      s = "From #{content_tag(:span, nil, class: 'slider-label-min')}".html_safe
      s << " to #{content_tag(:span, nil, class: 'slider-label-max')}".html_safe
    end
  end

  def price_slider_tag(options = {})
    slider_tag :price, options.reverse_merge(
        unit: current_currency&.name || 'GBP',
        min: Currency.convert(general_boat_stats.price_min, Currency.default, current_currency),
        max: Currency.convert(general_boat_stats.price_max, Currency.default, current_currency)
    )
  end

  def length_slider_tag(options = {})
    slider_tag :length, options.reverse_merge(
        unit: current_length_unit,
        min: Rightboat::Unit.convert_length(general_boat_stats.length_min, 'm', current_length_unit),
        max: Rightboat::Unit.convert_length(general_boat_stats.length_max, 'm', current_length_unit)
    )
  end

end
