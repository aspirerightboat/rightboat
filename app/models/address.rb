class Address < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper

  belongs_to :country
  belongs_to :addressible, polymorphic: true

  # validates_presence_of :country_id, :line1, :town_city
  alias_attribute :address, :line1
  alias_attribute :postcode, :zip
  alias_attribute :town, :town_city

  def country=(v)
    if v.is_a?(String)
      name = (v.upcase == 'UK') ? 'GB' : v
      country = Country.joins(:misspellings).where('misspellings.alias_string = :name OR name = :name OR iso = :name', name: name).first
      if country
        self[:country_id] = country.id
      # else
      #   self[:country_id]
      end
    else
      super
    end
  end

  def to_s(format = :html)
    state_zip = [county, zip].reject(&:blank?).join(', ')
    address = [line1, line2].reject(&:blank?).join(', ')
    lines = [address, town_city, state_zip, country].reject(&:blank?)

    if format && format.to_sym == :html
      sanitize(lines.join('<br>'), tags: ['br'])
    else
      lines.join(', ')
    end
  end

  def display_string; to_s(:str) end
end
