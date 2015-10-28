module Member
  class BaseController < ::ApplicationController
    before_action :load_search_facets_if_needed
    before_action :require_confirmed_email

    layout 'member'

    private

    def load_search_facets_if_needed
      load_search_facets if !request.xhr?
    end
  end
end