class LeadsMailer < ApplicationMailer
  layout 'mailer'

  def lead_created_notify_buyer(enquiry_id)
    @enquiry = Enquiry.find(enquiry_id)
    @boat = @enquiry.boat
    @office = @boat.office
    attach_boat_pdf

    mail(to: enquiry.email, subject: "Boat Enquiry ##{@boat.ref_no} - #{@boat.manufacturer} #{@boat.model}")
  end

  def lead_created_notify_broker(enquiry_id)
    @enquiry = Enquiry.find(enquiry_id)
    @boat = @enquiry.boat
    @office = @boat.office
    attach_boat_pdf
    to_email = @office.try(:email) || @boat.user.email
    mail_params = {to: to_email, subject: "Boat Enquiry ##{@boat.ref_no} - #{@boat.manufacturer} #{@boat.model}"}
    mail_params[:cc] = @boat.user.email if to_email != @boat.user.email

    mail(mail_params)
  end

  def lead_quality_check(enquiry_id)
    @enquiry = Enquiry.find(enquiry_id)
    to_email = RBConfig.store['lead_quality_check_email']
    mail(to: to_email, subject: "Broker wants review lead #{@enquiry.id} - Rightboat")
  end

  def invoicing_report(invoice_ids)
    @invoices = Invoice.where(id: invoice_ids).includes(:enquiries, :user).to_a

    to_email = RBConfig.store['invoicing_report_email']
    mail(to: to_email, subject: "Invoicing Report #{Time.current.to_date.to_s(:short)}")
  end

  def invoice_notify_broker(invoice_id)
    @invoice = Invoice.find(invoice_id)
    @broker = @invoice.user
    @broker_info = @broker.broker_info
    @leads = @invoice.enquiries.includes(:boat).order('id DESC')

    mail(to: @broker.email, subject: "Invoice Notification #{Time.current.to_date.to_s(:short)} - Rightboat")
  end

  def lead_reviewed_notify_broker(enquiry_id)
    @lead = Enquiry.find(enquiry_id)

    mail(to: @lead.boat.user.email, subject: "Lead reviewed Notification #{Time.current.to_date.to_s(:short)} - Rightboat")
  end

  private

  def attach_boat_pdf
    file_name = "#{@boat.manufacturer.slug}-#{@boat.slug}.pdf"
    attachments[file_name] = WickedPdf.new.pdf_from_string(render 'boats/pdf', layout: 'pdf')
  end

end
