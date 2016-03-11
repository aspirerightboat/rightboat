module Rightboat
  class CleverErrorsNotifier
    ERRORS_PER_HOUR_LIMIT = 10

    def self.try_notify(exception, request, current_user, context = nil)
      notified = false
      error_type = exception ? exception.class.name : context[:error_type]

      if ErrorEvent.where(error_type: error_type, notified: true).where('created_at > ?', 1.hour.ago).count < ERRORS_PER_HOUR_LIMIT
        ErrorsMailer.error_message(exception, request, current_user, context).deliver_now
        notified = true
      end

      err_context = {}
      err_context[:request] = {url: request.url} if request
      err_context[:user] = {id: current_user.id} if current_user
      err_context[:other] = context if context
      message = (exception.message if exception)
      backtrace = (exception.backtrace.join("\n") if exception)

      ErrorEvent.create!(error_type: error_type,
                         message: message,
                         context: err_context.to_s,
                         backtrace: backtrace,
                         notified: notified)
    end

  end
end
