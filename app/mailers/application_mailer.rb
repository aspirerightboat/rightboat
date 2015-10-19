class ApplicationMailer < ActionMailer::Base
  default from: 'do-not-reply@rightboat.com' #, bcc: 'notifications@rightboat.com'
  layout 'mailer'

  STAGING_EMAIL = ('info@rightboat.com' if !Rails.env.production?)
end