module Member
  class BaseController < ::ApplicationController
    before_filter :load_search_facets_if_needed
    before_filter :require_user_login!

    layout 'member'

    private

    def require_user_login!
      unless user_signed_in?
        render 'member/dashboard/index'
      end
    end

    def load_search_facets_if_needed
      load_search_facets if request.get? && !request.xhr?
    end
  end
end