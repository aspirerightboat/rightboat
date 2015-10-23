class SavedSearch < ActiveRecord::Base

  serialize :country, Array
  serialize :category, Array
  serialize :tax_status, Hash
  serialize :new_used, Hash
  serialize :boat_type, Array

  belongs_to :user

  def search_title
    not_defined = '..'
    currency_sym = Currency.cached_by_name(currency).try(:symbol)
    res = ''
    res << " Keyword=#{q}" if q.present?
    res << " BoatType=#{boat_type}" if boat_type.present?
    res << " Boat=#{manufacturer_model}" if manufacturer_model
    res << " Year=#{year_min.presence || not_defined}-#{year_max.presence || not_defined}" if year_min.present? || year_max.present?
    res << " Price=#{price_min.presence || not_defined}-#{price_max.presence || not_defined}#{currency_sym}" if price_min.present? || price_max.present?
    res << " Length=#{length_min.presence || not_defined}-#{length_max.presence || not_defined}#{length_unit}" if length_min.present? || length_max.present?
    res << " RefNo=#{ref_no}" if ref_no.present?
    res.strip!
    res #.html_safe
  end

  def to_search_params
    attributes
      .except('id', 'user_id', 'first_found_boat_id', 'created_at', 'alert', 'updated_at')
  end
end
