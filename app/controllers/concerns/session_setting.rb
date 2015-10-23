module SessionSetting
  extend ActiveSupport::Concern

  included do
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