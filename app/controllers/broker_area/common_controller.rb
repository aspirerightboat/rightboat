module BrokerArea
  class CommonController < ::ApplicationController
    before_action :require_confirmed_email
    before_action :require_broker_user
  end
end