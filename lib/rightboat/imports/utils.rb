module Rightboat
  module Imports
    module Utils
      extend ActiveSupport::Concern

      self.included do
        delegate :convert_unit, :cleanup_string, :url_param, :nbsp_char, to: :class

        private
        def self.url_param(url, k)
          h = Rack::Utils.parse_query(URI.parse(url).query)
          h[k]
        end

        def self.cleanup_string(source)
          if source.present? && source.is_a?(String)
            source.encode('UTF-8').gsub(nbsp_char, ' ').gsub(/[\s]+/, ' ').strip
          else
            source
          end
        end

        def self.nbsp_char
          Nokogiri::HTML('&nbsp;').text # nokogiri converts &nbsp; to some symbol if document is html
        end

        def self.convert_unit(value, unit)
          return value.to_f.round(2) if unit.blank?

          case unit.downcase
          when 'feet', 'ft', 'f' then value = value.to_f.ft_to_m.round(2)
          when /\A(metres?|meters?|m)\z/ then value = value.to_f.round(2)
          when 'kg', 'kgs', 'k' then value = value.to_f.round(2)
          when 'lbs' then value = (value.to_f * 0.453592).round(2)
          when /\A(tonnes?|t)\z/ then value = (value.to_f * 1000).round(2)
          when /\A(gallon|g)\z/ then value = (value.to_f * 3.78541).round(2)
          when /\A(liters?|litres?|l)\z/ then value = (value.to_f).round(2)
          when 'metres/feet' # invalid unit from http://www.nya.co.uk/boatsxml.php
          else ImportMailer.new_unit(unit).deliver_now
          end

          value.to_s =~ /^[0\.]+$/ ? nil : value
        end

      end
    end
  end
end