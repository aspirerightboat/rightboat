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
    min = options[:min] || @search_facets["min_#{field}".to_sym]
    max = options[:max] || @search_facets["max_#{field}".to_sym]
    v0 = options[:value0] || params["#{field}_min".to_sym]
    v1 = options[:value1] || params["#{field}_max".to_sym]

    html_options = {
      'data-input' => field,
      'data-min' => min,
      'data-max' => max,
      'data-value0' => v0,
      'data-value1' => v1,
      'data-unit' => options[:unit],
      id: "#{field}-slider",
      class: 'slider'
    }

    ret = content_tag :div, '', html_options
    ret += content_tag(:div, '', class: 'min-label')
    ret += content_tag(:div, '', class: 'max-label')

    ret.html_safe
  end

  def currency_tag(name, selected, options = {})
    selected = selected.is_a?(Currency) ? selected.name : selected
    currencies = Rails.cache.fetch "rb.currencies", expires_in: 1.hour do
      ret = Currency.where(name: %w(GBP EUR USD))
      ret += Currency.where('id NOT IN (?)', ret.map(&:id)).order(:name)
    end
    select_tag name, options_from_collection_for_select(currencies, :name, :display_symbol, selected), options
  end

  def sort_options(selected = nil)
    options_for_select(Rightboat::BoatSearch::SortTypes, selected || current_order_field)
  end

  def options_for_country_code
    options_for_select(Country.country_code_options)
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

  def country_tag(name)
    return select_tag(name, options_for_select(Country.country_options), prompt: 'Please select...', placeholder: 'Please select...', class: 'select-white country-select')
  end
end
