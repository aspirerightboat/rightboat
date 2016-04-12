module Rightboat
  module SolrRetry

    def solr_retry(retries = 3, &block)
      try = 1

      begin
        block.call
      rescue Errno::ECONNREFUSED, RSolr::Error::Http
        try += 1

        if try <= retries
          sleep(0.5.second)
          retry
        end
      end
    end

  end
end
