class LeadsMailer < ApplicationMailer
  add_template_helper BoatsHelper # for pdf
  add_template_helper QrcodeHelper # for pdf
  layout 'mailer'

  def lead_created_notify_buyer(enquiry_id)
    @enquiry = Enquiry.find(enquiry_id)
    @boat = @enquiry.boat
    @office = @boat.office
    attach_boat_pdf

    to_email = [STAGING_EMAIL || @enquiry.email]
    to_email << 'info@rightboat.com'
    mail(to: to_email, subject: "Boat Enquiry ##{@boat.ref_no} - #{@boat.manufacturer} #{@boat.model}")
  end

  def lead_created_notify_broker(enquiry_id)
    mail_params = lead_broker_params(enquiry_id)
    attach_boat_pdf
    mail(mail_params)
  end

  def lead_created_notify_pop_yachts(enquiry_id)
    mail_params = lead_broker_params(enquiry_id)
    mail(mail_params)
  end

  def lead_quality_check(enquiry_id)
    @enquiry = Enquiry.find(enquiry_id)
    to_email = [RBConfig[:lead_quality_check_email]]
    to_email << 'info@rightboat.com'
    mail(to: to_email, subject: "#{@enquiry.boat.user.name} wants to review lead ##{@enquiry.id}")
  end

  def invoicing_report(invoice_ids)
    @invoices = Invoice.where(id: invoice_ids).includes(:enquiries, :user).to_a

    to_email = [RBConfig[:invoicing_report_email]]
    to_email << 'info@rightboat.com'
    to_email.uniq!
    mail(to: to_email, subject: "Invoicing Report #{Time.current.to_date.to_s(:short)}")
  end

  def invoice_notify_broker(invoice_id)
    @invoice = Invoice.find(invoice_id)
    @broker = @invoice.user
    @broker_info = @broker.broker_info
    @leads = @invoice.enquiries.includes(:boat).order('id DESC')

    to_email = [STAGING_EMAIL] # do not send emails to brokers temporarily # [STAGING_EMAIL || @broker.email]
    to_email << 'info@rightboat.com'
    to_email.uniq!
    mail(to: to_email, subject: "Invoice Notification #{Time.current.to_date.to_s(:short)} - Rightboat")
  end

  def lead_reviewed_notify_broker(enquiry_id)
    @lead = Enquiry.find(enquiry_id)

    to_email = [STAGING_EMAIL || @lead.boat.user.email]
    to_email << 'info@rightboat.com'
    to_email.uniq!
    mail(to: to_email, subject: "Lead reviewed notification - #{@lead.name}, ##{@lead.id}")
  end

  def lead_status_changed(enquiry_id)
    @enquiry = Enquiry.find(enquiry_id)
    @boat = @enquiry.boat
    to_email = [STAGING_EMAIL || @enquiry.email]
    to_email << 'info@rightboat.com'

    mail(to: to_email, subject: "Enquiry status changed - Rightboat")
  end

  private

  def attach_boat_pdf
    file_name = "#{@boat.ref_no.downcase}-#{@boat.slug}.pdf"
    attachments[file_name] = WickedPdf.new.pdf_from_string(render 'boats/pdf', layout: 'pdf')
  end

  def lead_broker_params(enquiry_id)
    @enquiry = Enquiry.find(enquiry_id)
    @boat = @enquiry.boat
    @office = @boat.office

    user_email = STAGING_EMAIL || @boat.user.email
    office_email = STAGING_EMAIL || @office.try(:email) || @boat.user.email
    to_emails = []
    dist =  @boat.user.broker_info.lead_email_distribution
    to_emails << user_email if dist['user']
    to_emails << office_email if dist['office']
    to_emails << 'info@eyb.fr' if dist['eyb']
    to_emails << 'info@rightboat.com'
    to_emails.uniq!

    {to: to_emails, subject: "New enquiry from Rightboat, #{@enquiry.name}, Lead ##{@enquiry.id}"}
  end
end