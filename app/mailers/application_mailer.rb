class ApplicationMailer < ActionMailer::Base
  default from: '"Rightboat" <do-not-reply@rightboat.com>'
  layout 'mailer'

  STAGING_EMAIL = ('info@rightboat.com' if Rails.env.staging?)
end