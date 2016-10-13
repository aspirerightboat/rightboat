class ApplicationController < ActionController::Base
  LAYOUT_MODES = %w(gallery list thumbnail)

  module CurrentMethods
    extend ActiveSupport::Concern

    included do
      helper_method :current_currency, :current_length_unit, :current_layout_mode, :current_search_order,
                    :current_user, :current_admin
    end

    private

    def current_currency
      @current_currency ||= begin
        Currency.cached_by_name(session[:currency]) ||
            (location = safe_geocoder_location) && Country.find_by(iso: location.country_code)&.currency ||
            Currency.default
      end
    end

    def set_current_currency(currency_name)
      if currency_name.present? && (cur = Currency.cached_by_name(currency_name))
        session[:currency] = cur.name
      end
    end

    def current_length_unit
      @current_length_unit ||= session[:length_unit] || 'ft'
    end

    def set_current_length_unit(unit)
      if unit.present? && Boat::LENGTH_UNITS.include?(unit)
        session[:length_unit] = unit
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

    def update_user_settings
      return unless current_user
      user_setting = current_user.user_setting
      user_setting.country_iso = session[:country]
      user_setting.length_unit = session[:length_unit]
      user_setting.currency = session[:currency]
      user_setting.save
    end

    def current_search_order
      @current_search_order ||= cookies[:search_order] || 'price_desc'
    end

    def set_current_search_order(order)
      if order.present? && Rightboat::SearchParams::ORDER_TYPES.include?(order)
        cookies[:search_order] = order
      end
    end

    def current_user
      @current_user ||= if session[:view_as_user_id] && !request.path.start_with?('/admin/') && current_admin
                          User.find_by(id: session[:view_as_user_id])
                        else
                          warden.authenticate(scope: :user)
                        end
    end

    def current_admin
      @current_admin ||= begin
        user = warden.authenticate(scope: :user)
        user if user&.admin?
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
end
