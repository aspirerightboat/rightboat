class RBDeviseMailer < Devise::Mailer
  helper NumbersHelper
  helper MailerHelper

  include Devise::Controllers::UrlHelpers
  default template_path: 'devise/mailer'
end
