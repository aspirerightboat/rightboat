class Address < ApplicationRecord
  belongs_to :country
  belongs_to :addressible, polymorphic: true

  def display_string(format)
    components = [line1, line2, line3, town_city, county, zip, state, country&.iso].select(&:present?)
    if components.any?
      case format
      when :raw then components.join(', ')
      when :html then components.map { |c| ERB::Util.html_escape(c) }.join('<br>').html_safe
      end
    end
  end

  def all_lines
    [line1, line2, line3].select(&:present?).join(', ')
  end

end
