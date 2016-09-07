class ErrorsMailer < ApplicationMailer
  layout 'errors_mailer'
  helper :backtrace

  default to: ApplicationMailer::DEVELOPER_EMAILS

  after_action :gmail_delivery

  def error_message(exception, request, user, context = nil)
    @exception = exception
    @request = request
    @user = user
    @context = context

    if exception
      @error_class = exception.class.to_s
      @error_message = exception.message
      @backtrace = exception.backtrace
    end

    if request
      @controller = request.params[:controller]
      @action = request.params[:action]
      @method = request.method
      @url = request.url
      @session = request.session.keys.map { |k| [k, request.session[k]] }
      @params = request.params.select { |k| k != 'controller' && k != 'action' }
                    .map { |k, v| k =~ /\A(?:password|password_confirmation|old_password)\z/ ? '[FILTERED]' : v }
      @env = request.env.slice(*ActionDispatch::Request::ENV_METHODS)
    end

    error_type = @error_class || context && context[:error_type]
    error_location = ("#{@controller}##{@action}" if request) || context && context[:error_location]
    @error_title = "#{error_type} in #{error_location}"

    mail(subject: "Error on Rightboat: #{@error_title}")
  end

end
