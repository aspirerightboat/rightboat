class ApplicationController < ActionController::Base

  rescue_from StandardError, with: :handle_exception if Rails.env.production?

  private

  def handle_exception(exception)
    case exception
    when ActiveRecord::RecordNotFound,
        ActionController::RoutingError,
        ActionController::UnknownFormat
      redirect_to_not_found
    when Rightboat::SolrIsDownError
      redirect_to_maintenance
    else
      Rightboat::CleverErrorsNotifier.try_notify(exception, request, current_user)
      if Rails.env.production?
        render file: "#{Rails.root}/public/500.html", status: 500, layout: false
      else
        raise exception
      end
    end
  end

end
