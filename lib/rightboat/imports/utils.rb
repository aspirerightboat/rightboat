module Rightboat
  module Imports
    module Utils
      extend ActiveSupport::Concern

      self.included do
        delegate :cleanup_string, :url_param, :nbsp_char, to: :class

        private
        def self.url_param(url, k)
          h = CGI::parse(url)
          h[k.to_s].try(&:first)
        end

        def self.cleanup_string(source)
          if source.is_a?(String) && !source.blank?
            source.encode('UTF-8').gsub(nbsp_char, ' ').gsub(/[\s\r\t\n]+/, ' ').strip
          else
            source
          end
        end

        def self.nbsp_char
          Nokogiri::HTML('&nbsp;').text
        end

        def convert_unit(value, unit)
          return value.to_f.round(2) if unit.blank?
          case unit.downcase
            when 'feet', 'ft' then value = (value.to_f * 0.3048).round(2)
            when 'metres', 'meters' then value = value.to_f.round(2)
            when 'kg', 'kgs' then value = value.to_f.round(2)
            when 'lbs' then value = (value.to_f * 0.453592).round(2)
            when 'tonnes' then value = (value.to_f * 1000).round(2)
            when /gallon/ then value = (value.to_f * 3.78541).round(2)
            when /(liter|litre)(s)?/ then value = (value.to_f).round(2)
            else
              # TODO: report new unit by mail
              raise "Wrong unit #{unit}"
          end
          value.to_s =~ /^[0\.]+$/ ? nil : value
        end

      end
    end
  end
end