module Rightboat::DelayedJobNotifyOnError

  def error(job, exception)
    if Rails.env.production?
      case exception
      when EOFError, RSolr::Error::Http, Errno::ECONNREFUSED # these errors are temporary while solr is restarting
        return if job.attempts < 3
      end

      context = {job: {id: job.id, handler: job.handler}, error_location: 'Delayed Job Worker'}
      Rightboat::CleverErrorsNotifier.try_notify(exception, nil, nil, context)
    end
  end

end
