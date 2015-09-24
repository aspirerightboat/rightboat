class SavedSearch < ActiveRecord::Base
  belongs_to :user

  def in_short
    not_defined = '..'
    currency_sym = Currency.find_by(name: currency).try(:symbol)
    year = "#{year_min.presence || not_defined}-#{year_max.presence || not_defined}" if year_min.present? || year_max.present?
    price = "#{price_min.presence || not_defined}-#{price_max.presence || not_defined}#{currency_sym}" if price_min.present? || price_max.present?
    length = "#{length_min.presence || not_defined}-#{length_max.presence || not_defined}#{length_unit}" if length_min.present? || length_max.present?

    "#{manufacturer_model} #{year} #{price} #{length} #{ref_no}".strip
  end
end
