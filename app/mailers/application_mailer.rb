class ApplicationMailer < ActionMailer::Base
  default from: '"Rightboat" <do-not-reply@rightboat.com>'
  layout 'mailer'
  add_template_helper NumbersHelper

  STAGING_EMAIL = ('info@rightboat.com' if Rails.env.staging?)
  DEVELOPER_EMAILS = %w(don.fuller@cotoco.com llukomskyy@n-ix.com xmpolaris@hotmail.com)
end