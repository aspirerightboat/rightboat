class BrokerIframe < ActiveRecord::Base
  serialize :filters

  belongs_to :user

  before_validation :ensure_token

  def ensure_token
    self.token ||= SecureRandom.hex[0..16]
  end

  def filter_manufacturer_names
    Manufacturer.where(id: filters[:manufacturer_ids]).pluck(:name) if filters && filters[:manufacturer_ids]
  end

  def filter_country_names
    Country.where(id: filters[:country_ids]).pluck(:name) if filters && filters[:country_ids]
  end

  def filtered_boats
    boats_rel = user_boats_only ? user.boats : Boat
    boats_rel = boats_rel.where(country_id: filters[:country_ids]) if filters && filters[:country_ids].present?
    boats_rel = boats_rel.where(manufacturer_id: filters[:manufacturer_ids]) if filters && filters[:manufacturer_ids].present?
    boats_rel
  end
end
