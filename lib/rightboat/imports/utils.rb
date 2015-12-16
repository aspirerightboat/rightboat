module Rightboat
  module Imports
    module Utils
      HTML_NBSP = Nokogiri::HTML.fragment('&nbsp;').text
      WHITESPACES_REGEX = /[\s#{HTML_NBSP}]+/

      extend ActiveSupport::Concern

      self.included do
        delegate :cleanup_string, :url_param, to: :class

        private
        def self.url_param(url, k)
          h = Rack::Utils.parse_query(URI.parse(url).query)
          h[k]
        end


        def self.cleanup_string(source)
          if source.present? && source.is_a?(String)
            source.encode('UTF-8').gsub(WHITESPACES_REGEX, ' ').strip
          else
            source
          end
        end

      end
    end
  end
end