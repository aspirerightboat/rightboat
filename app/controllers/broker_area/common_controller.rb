module BrokerArea
  class CommonController < ::ApplicationController
    before_action :require_broker_user
  end
end
