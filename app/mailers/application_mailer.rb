class ApplicationMailer < ActionMailer::Base
  default from: '"Rightboat" <do-not-reply@rightboat.com>', bcc: 'rightboat911716@sugarondemand.com', cc: 'info@rightboat.com'
  layout 'mailer'

  STAGING_EMAIL = ('info@rightboat.com' if Rails.env.staging?)
end