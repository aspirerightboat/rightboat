class ApplicationController < ActionController::Base

  rescue_from StandardError, with: :handle_exception if Rails.env.production?

  private

  def handle_exception(exception)
    case exception
    when ActiveRecord::RecordNotFound,
        ActionController::RoutingError,
        ActionController::UnknownFormat
      render file: "#{Rails.root}/public/404.html", layout: false, status: :not_found
    when Rightboat::SolrIsDownError
      render file: "#{Rails.root}/public/503.html", layout: false, status: :service_unavailable
    else
      Rightboat::CleverErrorsNotifier.try_notify(exception, request, current_user)
      if Rails.env.production?
        render file: "#{Rails.root}/public/500.html", layout: false, status: :internal_server_error
      else
        raise exception
      end
    end
  end

end
