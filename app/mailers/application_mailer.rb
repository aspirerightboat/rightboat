class ApplicationMailer < ActionMailer::Base
  default from: '"Rightboat" <do-not-reply@rightboat.com>'
  layout 'mailer'
  add_template_helper NumbersHelper
  add_template_helper MailerHelper

  STAGING_EMAIL = ('info@rightboat.com' if Rails.env.staging?)
  DEVELOPER_EMAILS = %w(don.fuller@cotoco.com llukomskyy@n-ix.com xmpolaris@hotmail.com)

  private

  def attach_boat_pdf
    file_path = Rightboat::BoatPdfGenerator.ensure_pdf(@boat)
    attachments[File.basename(file_path)] = File.read(file_path)
  end
end
