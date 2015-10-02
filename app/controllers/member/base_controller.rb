module Member
  class BaseController < ::ApplicationController
    before_filter :load_search_facets_if_needed
    before_filter :require_user_login!

    layout 'member'

    private

    def require_user_login!
      redirect_to member_root_path unless user_signed_in?
    end

    def load_search_facets_if_needed
      load_search_facets if request.get? && !request.xhr?
    end
  end
end