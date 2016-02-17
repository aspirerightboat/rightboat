module Rightboat
  module Imports
    module Utils

      def url_param(url, k)
        h = Rack::Utils.parse_query(URI.parse(url).query)
        h[k]
      end

    end
  end
end