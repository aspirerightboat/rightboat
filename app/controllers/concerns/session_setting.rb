module SessionSetting
  extend ActiveSupport::Concern

  included do
    def set_currency(new_currency = nil)
      if new_currency
        new_name = new_currency.respond_to?(:name) ? new_currency.name : new_currency
        cookies[:currency] = new_name
        @_current_currency = Currency.find_by_name(cookies[:currency])
      else
        if request.location
          country = Country.find_by_iso(request.location.country_code)
        else
          country = nil
        end

        currency = country.try(&:currency) || Currency.default
        cookies[:currency] = currency.name
        @_current_currency = currency
      end
    end

    def set_view_layout(mode)
      return if mode.blank? || !['gallery', 'list', 'thumbnail'].include?(mode.to_s.downcase)
      cookies[:view_layout] = mode.to_s.downcase
    end

    def set_order_field(field)
      return if field.blank? || Rightboat::BoatSearch::SortTypes.values.include?(field.to_s.downcase)
      cookies[:order_field] = field.to_s.downcase
    end

    def set_length_unit(unit)
      return if unit.blank? || !['ft', 'm'].include?(unit.to_s.downcase)
      cookies[:length_unit] = unit.to_s.downcase
    end
  end
end