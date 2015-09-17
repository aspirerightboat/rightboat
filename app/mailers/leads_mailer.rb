class LeadsMailer < ApplicationMailer
  layout 'mailer'

  def lead_created_notify_buyer(enquiry)
    @enquiry = enquiry
    @boat = enquiry.boat
    @office = @boat.office

    file_name = "#{@boat.manufacturer.slug}-#{@boat.slug}.pdf"
    attachments[file_name] = render pdf: 'boats/show'

    mail(to: enquiry.email, subject: "Boat Enquiry #{@boat.ref_no} - #{@boat.manufacturer} #{@boat.model}")
  end

  def lead_created_notify_broker(enquiry)
    @enquiry = enquiry
    @boat = enquiry.boat
    @office = @boat.office
    to_email = @office.try(:email) || @boat.user.email
    mail_params = {to: to_email, subject: "Boat Enquiry #{@boat.ref_no} - #{@boat.manufacturer} #{@boat.model}"}
    mail_params[:cc] = @boat.user.email if to_email != @boat.user.email

    file_name = "#{@boat.manufacturer.slug}-#{@boat.slug}.pdf"
    attachments[file_name] = render pdf: 'boats/show'

    mail(mail_params)
  end
end
