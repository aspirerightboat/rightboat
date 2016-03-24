class ApplicationMailer < ActionMailer::Base
  default from: '"Rightboat" <do-not-reply@rightboat.com>'
  layout 'mailer'
  add_template_helper NumbersHelper

  STAGING_EMAIL = ('info@rightboat.com' if Rails.env.staging?)
  DEVELOPER_EMAILS = %w(don.fuller@cotoco.com llukomskyy@n-ix.com xmpolaris@hotmail.com)

  private

  def attach_boat_pdf
    file_name = "Rightboat-#{[@boat.manufacturer, @boat.model].reject(&:blank?).join('-')}-#{@boat.ref_no}.pdf"
    attachments[file_name] = WickedPdf.new.pdf_from_string(render 'boats/pdf', layout: 'pdf')
  end
end