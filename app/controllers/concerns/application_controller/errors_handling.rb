class ApplicationController < ActionController::Base
  module ErrorsHandling
    extend ActiveSupport::Concern

    included do
      rescue_from Exception, with: :handle_exception if Rails.env.production?
    end

    private

    def handle_exception(exception)
      case exception
      when ActiveRecord::RecordNotFound,
          ActionController::RoutingError,
          ActionController::UnknownFormat,
          ActionController::InvalidAuthenticityToken
        render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
      when SolrIsDownError
        render file: "#{Rails.root}/public/503.html", layout: false, status: :service_unavailable
      else
        if exception.is_a?(StandardError) || exception.is_a?(ScriptError)
          Rightboat::CleverErrorsNotifier.try_notify(exception, request, current_user)

          if Rails.env.production?
            render file: "#{Rails.root}/public/500.html", layout: false, status: :internal_server_error
            return
          end
        end

        raise exception
      end
    end

  end
end
