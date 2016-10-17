class SolrIsDownError < StandardError; end

module RetryableSolrSearch
  extend ActiveSupport::Concern

  DEFAULT_RETRIES = 3

  module ClassMethods

    def retryable_solr_search(options = {}, &block)
      retries = options.delete(:retries) || DEFAULT_RETRIES
      raise_exception = options.delete(:raise_exception)
      try = 1

      begin
        solr_search(options, &block)
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

    def retryable_solr_search!(options = {}, &block)
      retryable_solr_search(options.merge!(raise_exception: true), &block)
    end

  end
end

ActiveRecord::Base.send(:include, RetryableSolrSearch)
