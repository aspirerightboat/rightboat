class ApplicationController < ActionController::Base

  LAYOUT_MODES = %w(gallery list thumbnail)
  LENGTH_UNITS = %w(ft m)
  helper_method :current_currency, :current_length_unit, :current_layout_mode, :current_search_order, :current_broker

  def current_currency
    @current_currency ||= begin
      Currency.cached_by_name(cookies[:currency]) ||
      (location = safe_geocoder_location) && Country.find_by(iso: location.country_code).try(:currency) ||
      Currency.default
    end
  end

  def set_current_currency(currency_name)
    if currency_name.present? && (cur = Currency.cached_by_name(currency_name))
      cookies[:currency] = cur.name
    end
  end

  def current_length_unit
    @current_length_unit ||= cookies[:length_unit] || 'ft'
  end

  def set_current_length_unit(unit)
    if unit.present? && LENGTH_UNITS.include?(unit)
      cookies[:length_unit] = unit
    end
  end

  def current_layout_mode
    @current_layout_mode ||= cookies[:layout_mode] || 'gallery'
  end

  # def set_current_view_layout(mode)
  #   if mode.present? && LAYOUT_MODES.include?(mode)
  #     cookies[:layout_mode] = mode
  #   end
  # end


  def current_search_order
    @current_search_order ||= cookies[:search_order] || 'score_desc'
  end

  def set_current_search_order(order)
    if order.present? && Rightboat::BoatSearch::ORDER_TYPES.include?(order)
      cookies[:search_order] = order
    end
  end

  def current_broker
    if current_user.try(:admin?)
      @current_broker ||= User.find_by(id: cookies[:broker_id])
    else
      @current_broker ||= current_user
    end
  end

  def safe_geocoder_location
    begin
      request.location
    rescue Errno::ENETUNREACH => e
      logger.error "#{e.class.name}: #{e.message}\n#{e.backtrace.join("\n")}"
      nil
    end
  end
end