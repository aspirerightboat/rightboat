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

  def currency_select(name, selected, options = {})
    selected = selected.is_a?(Currency) ? selected.name : selected
    select_tag name, options_for_select(Currency.pluck(:symbol, :name), selected), options
  end

  def search_order_options
    opts = Rightboat::SearchParams::ORDER_TYPES.map { |type| [t("search_orders.#{type}"), type] }
    options_for_select(opts, params[:order] || current_search_order)
  end

  def layout_mode_options
    options_for_select(ApplicationController::LAYOUT_MODES, current_layout_mode)
  end

  def options_for_country_code(selected_code = nil)
    Country.country_code_options.each_with_object(String.new) do |(name, iso, code), s|
      s << content_tag(:option, "#{name} (#{code})", value: code, data: ({iso: iso} if iso), selected: (true if selected_code == code))
    end.html_safe
  end

  def length_unit_options
    options_for_select(Boat::LENGTH_UNITS, current_length_unit)
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

  def general_boat_stats
    @general_boat_stats ||= Rightboat::GeneralBoatStats.fetch
  end

  def home_image_url(current_user = nil)
    media_url = asset_url('home-bg.jpg')

    return media_url # unless current_user

    # if session[:boat_type].present?
    #   media_url = HomeSetting.find_by(boat_type: session[:boat_type])&.attached_media || media_url
    # end
    #
    # asset_url(media_url)
  end
end
