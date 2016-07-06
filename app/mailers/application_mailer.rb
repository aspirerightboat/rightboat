class ApplicationMailer < ActionMailer::Base
  default from: '"Rightboat" <info@rightboat.com>'
  layout 'mailer'
  add_template_helper NumbersHelper
  add_template_helper MailerHelper

  STAGING_EMAIL = ('info@rightboat.com' if Rails.env.staging?)
  DEVELOPER_EMAILS = %w(llukomskyy@n-ix.com sieraruo@gmail.com)

  private

  def gmail_delivery
    mail.delivery_method.settings = Rails.application.secrets.gmail_smtp
  end

  def amazon_delivery
    #return gmail_delivery if Rails.env.staging?
    mail.delivery_method.settings = Rails.application.secrets.amazon_smtp
  end

  def attach_boat_pdf
    file_path = Rightboat::BoatPdfGenerator.ensure_pdf(@boat)
    attachments[File.basename(file_path)] = File.read(file_path)
  end

  def attach_boat_zip(file_path)
    attachments[File.basename(file_path)] = File.read(file_path)
  end
end
