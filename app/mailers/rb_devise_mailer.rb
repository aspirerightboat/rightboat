class RBDeviseMailer < Devise::Mailer
  helper NumbersHelper
  helper MailerHelper

  include Devise::Controllers::UrlHelpers
  default template_path: 'devise/mailer'

  after_action :amazon_delivery

  def amazon_delivery
    mail.delivery_method.settings = Rails.application.secrets.amazon_smtp
  end

end
