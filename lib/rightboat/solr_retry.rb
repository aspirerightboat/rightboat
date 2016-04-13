module Rightboat
  class SolrIsDownError < StandardError; end

  module SolrRetry

    def solr_retry(retries: 3, raise_exception: false, &block)
      try = 1

      begin
        block.call
      rescue Errno::ECONNREFUSED, RSolr::Error::Http
        if try < retries
          try += 1
          sleep(0.5.second)
          retry
        elsif raise_exception
          raise SolrIsDownError.new
        end
      end
    end

  end
end
