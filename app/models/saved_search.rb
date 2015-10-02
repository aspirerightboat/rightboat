class SavedSearch < ActiveRecord::Base
  belongs_to :user

  def search_title
    not_defined = '..'
    currency_sym = Currency.find_by(name: currency).try(:symbol)
    res = ''
    res << " Boat=#{manufacturer_model}" if manufacturer_model
    res << " Year=#{year_min.presence || not_defined}-#{year_max.presence || not_defined}" if year_min.present? || year_max.present?
    res << " Price=#{price_min.presence || not_defined}-#{price_max.presence || not_defined}#{currency_sym}" if price_min.present? || price_max.present?
    res << " Length=#{length_min.presence || not_defined}-#{length_max.presence || not_defined}#{length_unit}" if length_min.present? || length_max.present?
    res << " RefNo=#{ref_no}" if ref_no.present?
    res.strip!
    res #.html_safe
  end

  def to_search_params
    {
        year_min: year_min,
        year_max: year_max,
        price_min: price_min,
        price_max: price_max,
        length_min: length_min,
        length_max: length_max,
        length_unit: length_unit,
        manufacturer_model: manufacturer_model,
        currency: currency,
        ref_no: ref_no,
    }
  end
end
