module Rightboat
  module Imports
    module Utils
      extend ActiveSupport::Concern

      self.included do
        delegate :cleanup_string, :url_param, :nbsp_char, to: :class

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

      end
    end
  end
end