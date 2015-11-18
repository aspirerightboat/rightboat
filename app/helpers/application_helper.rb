module ApplicationHelper
  include Twitter::Autolink

  def nav_class_for(condition)
    if condition.is_a?(Regexp)
      return 'active' if "#{controller_path}##{action_name}" =~ condition
    else
      controller, action = condition.to_s.split('#')
      return 'active' if (controller_path.blank? || controller == controller_path) && (action.blank? || action == action_name)
    end
  end

  # Options
  def slider_tag(field, options = {})
    key_min = :"#{field}_min"
    key_max = :"#{field}_max"
    min = options[:min] || convert_to_current_unit(field, general_facets[key_min])
    max = options[:max] || convert_to_current_unit(field, general_facets[key_max])
    v0 = params[key_min].presence || convert_to_current_unit(field, @search_facets.try(:[], key_min))
    v1 = params[key_max].presence || convert_to_current_unit(field, @search_facets.try(:[], key_max))

    html_options = {
      'data-input' => field,
      'data-min' => min,
      'data-max' => max,
      'data-value0' => v0,
      'data-value1' => v1,
      'data-unit' => options[:unit],
      class: "slider #{field}-slider"
    }

    ret = content_tag(:div, '', html_options)
    ret << content_tag(:div, '', class: 'min-label')
    ret << content_tag(:div, '', class: 'max-label')

    ret.html_safe
  end

  def convert_to_current_unit(field, value)
    return if !value
    if field == :length
      value.to_f.m_to_ft if current_length_unit == 'ft'
    elsif field == :price
      Currency.convert(value, Currency.default, current_currency)
    else
      value
    end
  end

  def currency_tag(name, selected, options = {})
    selected = selected.is_a?(Currency) ? selected.name : selected
    currencies = Rails.cache.fetch "rb.currencies", expires_in: 1.hour do
      ret = Currency.where(name: %w(GBP EUR USD))
      ret += Currency.where('id NOT IN (?)', ret.map(&:id)).order(:name)
    end
    select_tag name, options_from_collection_for_select(currencies, :name, :display_symbol, selected), options
  end

  def search_order_options
    opts = Rightboat::BoatSearch::ORDER_TYPES.map { |type| [t("search_orders.#{type}"), type] }
    options_for_select(opts, current_search_order)
  end

  def layout_mode_options
    opts = ApplicationController::LAYOUT_MODES.map { |m| [m.capitalize, m] }
    options_for_select(opts, current_layout_mode)
  end

  def options_for_country_code
    options_for_select(Country.country_code_options)
  end

  def length_unit_options
    options_for_select(ApplicationController::LENGTH_UNITS, current_length_unit)
  end

  def tel_to(text)
    groups = text.to_s.scan(/(?:^\+)?\d+/)
    link_to text, "tel:#{groups.join('-')}"
  end

  def meta_description(body)
    safe_text = body.gsub(/<[^>]*>/,'').gsub(/[\r\n\s\t]+/, ' ')
    size = 0
    safe_text.split.reject do |token|
      size += token.size
      size >= 160
    end.join(" ") + (safe_text.size >= 160 ? " ..." : "")
  end

  def nice_phone(phone_with_code)
    return if phone_with_code.blank?
    code, phone = phone_with_code.split('-')
    "+(#{code}) #{phone}"
  end

  def country_tag(name, selected=nil, options={})
    select_tag(name, options_for_select(Country.country_options, selected), options)
  end

  def general_facets
    @general_facets ||= Rightboat::BoatSearch.general_facets_cached
  end

  def bootstrap_class_for(flash_type)
    case flash_type.to_sym
      when :alert
        "warning"
      when :notice
        "info"
      else
        flash_type.to_s
    end
  end
end
