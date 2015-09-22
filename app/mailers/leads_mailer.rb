class LeadsMailer < ApplicationMailer
  layout 'mailer'

  def lead_created_notify_buyer(enquiry)
    @enquiry = enquiry
    @boat = enquiry.boat
    @office = @boat.office
    attach_boat_pdf

    mail(to: enquiry.email, subject: "Buyer Lead Notification - #{@boat.manufacturer} #{@boat.model} #{@boat.ref_no} - Rightboat")
  end

  def lead_created_notify_broker(enquiry)
    @enquiry = enquiry
    @boat = enquiry.boat
    @office = @boat.office
    attach_boat_pdf
    to_email = @office.try(:email) || @boat.user.email
    mail_params = {to: to_email, subject: "Broker Lead Notification - #{@boat.ref_no} - #{@boat.manufacturer} #{@boat.model} - Rightboat"}
    mail_params[:cc] = @boat.user.email if to_email != @boat.user.email

    mail(mail_params)
  end

  def broker_requested_quality_check(enquiry)
    @enquiry = enquiry
    mail(to: 'boats@rightboat.com', subject: "Broker wants review lead #{@enquiry.id} - Rightboat")
  end

  private

  def attach_boat_pdf
    file_name = "#{@boat.manufacturer.slug}-#{@boat.slug}.pdf"
    attachments[file_name] = WickedPdf.new.pdf_from_string(render 'boats/pdf', layout: 'pdf')
  end

end
