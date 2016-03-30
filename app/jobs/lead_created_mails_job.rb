class LeadCreatedMailsJob < ActiveJob::Base
  def perform(lead_id)
    lead = Enquiry.find(lead_id)
    boat = lead.boat

    Rightboat::BoatPdfGenerator.ensure_pdf(boat)

    LeadsMailer.lead_created_notify_buyer(lead_id).deliver_later

    broker = boat.user
    if %w(nick@popsells.com).include? broker.email
      LeadsMailer.lead_created_notify_pop_yachts(lead_id).deliver_later
    elsif broker.payment_method_present?
      LeadsMailer.lead_created_notify_broker(lead_id).deliver_later
    else
      LeadsMailer.lead_created_tease_broker(lead_id).deliver_later
    end
  end
end
