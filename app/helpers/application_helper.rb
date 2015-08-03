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
    v1 = options[:value1] || params["#{field}_min".to_sym]; v1 = v1.blank? ? min : v1
    v2 = options[:value2] || params["#{field}_max".to_sym]; v2 = v2.blank? ? max : v2

    html_options = {
      'data-input' => field,
      'data-min' => min,
      'data-max' => max,
      'data-value1' => v1,
      'data-value2' => v2,
      'data-unit' => options[:unit],
      'data-slide-name' => field,
      id: "#{field}-slider",
      class: 'slider'
    }
    html_options = html_options.merge(options[:html] || {})

    ret = content_tag :div, '', html_options
    ret += content_tag(:div, '', class: 'min-label')
    ret += content_tag(:div, '', class: 'max-label')

    ret.html_safe
  end

  def currency_tag(name, selected, options = {})
    select_tag name, options_from_collection_for_select(Currency.active, :name, :display_symbol, selected), options
  end

  def sort_options(selected = nil)
    options_for_select(Rightboat::BoatSearch::SortTypes, selected || current_order_field)
  end

end
