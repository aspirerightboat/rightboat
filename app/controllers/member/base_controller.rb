module Member
  class BaseController < ::ApplicationController
    before_action :require_confirmed_email

    layout 'member'
  end
end