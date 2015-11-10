class ApplicationController < ActionController::Base

  LAYOUT_MODES = %w(gallery list thumbnail)
  LENGTH_UNITS = %w(ft m)

  def current_currency
    @current_currency ||= Currency.cached_by_name(cookies[:currency]) ||
        (Country.find_by(iso: request.location.country_code).try(:currency) if request.location) ||
        Currency.default
  end
  helper_method :current_currency

  def set_current_currency(currency_name)
    if currency_name.present? && (cur = Currency.cached_by_name(currency_name))
      cookies[:currency] = cur
    end
  end


  def current_length_unit
    @current_length_unit ||= cookies[:length_unit] || 'ft'
  end
  helper_method :current_length_unit

  def set_current_length_unit(unit)
    if unit.present? && LENGTH_UNITS.include?(unit)
      cookies[:length_unit] = unit
    end
  end


  def current_layout_mode
    @current_layout_mode ||= cookies[:layout_mode] || 'gallery'
  end
  helper_method :current_layout_mode

  # def set_current_view_layout(mode)
  #   if mode.present? && LAYOUT_MODES.include?(mode)
  #     cookies[:layout_mode] = mode
  #   end
  # end


  def current_search_order
    @current_search_order ||= cookies[:search_order] || 'price_desc'
  end
  helper_method :current_search_order

  def set_current_search_order(field)
    if field.present? && Rightboat::BoatSearch::ORDER_TYPES.include?(field)
      cookies[:search_order] = field
    end
  end

end