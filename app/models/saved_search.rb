class SavedSearch < ActiveRecord::Base

  serialize :country, Array
  serialize :category, Array
  serialize :tax_status, Hash
  serialize :new_used, Hash

  belongs_to :user

  def search_title
    not_defined = '..'
    currency_sym = Currency.cached_by_name(currency).try(:symbol)
    res = ''
    res << " Keyword=\"#{q}\"" if q.present?
    res << " BoatType=\"#{boat_type}\"" if boat_type.present?
    res << " Boat=\"#{manufacturer_model}\"" if manufacturer_model.present?
    res << " Year=#{year_min.presence || not_defined}-#{year_max.presence || not_defined}" if year_min.present? || year_max.present?
    res << " Price=#{currency_sym}#{price_min.presence || 0}-#{price_max.presence || not_defined}" if price_min.present? || price_max.present?
    res << " Length=#{length_min.presence || not_defined}-#{length_max.presence || not_defined}#{length_unit}" if length_min.present? || length_max.present?
    res << " RefNo=\"#{ref_no}\"" if ref_no.present?
    res << " Order=\"#{order}\"" if order.present?
    res.strip!
    res
  end

  def to_search_params
    attributes.except('id', 'user_id', 'first_found_boat_id', 'created_at', 'alert', 'updated_at').symbolize_keys
  end
end
