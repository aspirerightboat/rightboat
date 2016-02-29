class LeadsMailer < ApplicationMailer
  default bcc: 'rightboat911716@sugarondemand.com', cc: 'info@rightboat.com'
  add_template_helper BoatsHelper # for pdf
  add_template_helper QrcodeHelper # for pdf
  layout 'mailer'

  def lead_created_notify_buyer(enquiry_id)
    @enquiry = Enquiry.find(enquiry_id)
    @boat = @enquiry.boat
    @office = @boat.office
    attach_boat_pdf

    to_email = STAGING_EMAIL || @enquiry.email
    mail(to: to_email, subject: "Boat Enquiry ##{@boat.ref_no} - #{@boat.manufacturer} #{@boat.model}")
  end

  def lead_created_tease_broker(enquiry_id)
    mail_params = lead_broker_params(enquiry_id)
    mail(mail_params)
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
    to_email = RBConfig[:lead_quality_check_email]
    mail(to: to_email, subject: "#{@enquiry.boat.user.name} wants to review lead ##{@enquiry.id}")
  end

  def invoicing_report(invoice_ids)
    @invoices = Invoice.where(id: invoice_ids).includes(:enquiries, :user).to_a
    @grand_total = @invoices.map(&:total_ex_vat).sum

    to_email = RBConfig[:invoicing_report_email]
    mail(to: to_email, subject: "Invoicing Report #{Time.current.to_date.to_s(:short)}")
  end

  def invoice_notify_broker(invoice_id)
    @invoice = Invoice.find(invoice_id)
    @broker = @invoice.user
    @broker_info = @broker.broker_info
    @leads = @invoice.enquiries.includes(:boat).order('id DESC')

    to_email = STAGING_EMAIL # do not send emails to brokers temporarily # STAGING_EMAIL || @broker.email
    mail(to: to_email, subject: "Invoice Notification #{Time.current.to_date.to_s(:short)} - Rightboat")
  end

  def lead_reviewed_notify_broker(enquiry_id)
    @lead = Enquiry.find(enquiry_id)

    to_email = STAGING_EMAIL || @lead.boat.user.email
    mail(to: to_email, subject: "Lead reviewed notification - #{@lead.name}, ##{@lead.id}")
  end

  def suspicious_lead(lead_id, title)
    @lead = Enquiry.find(lead_id)
    @boat = @lead.boat
    mail(to: 'info@rightboat.com', subject: "#{title} - Rightboat")
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

    @broker = @boat.user
    broker_email = STAGING_EMAIL || @broker.email
    office_email = STAGING_EMAIL || @office.try(:email) || @broker.email
    to_emails = []
    dist =  @broker.broker_info.lead_email_distribution
    to_emails << broker_email if dist['user']
    to_emails << office_email if dist['office']
    to_emails << 'info@eyb.fr' if dist['eyb']
    to_emails.uniq!

    buyer_name_part = ", #{@enquiry.name}" if @broker.payment_method_present?
    {to: to_emails, subject: "New enquiry from Rightboat#{buyer_name_part}, Lead ##{@enquiry.id}"}
  end
end