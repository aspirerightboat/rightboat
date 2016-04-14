class LeadCreatedMailsJob
  def initialize(lead_id)
    @lead_id = lead_id
  end

  def perform
    lead = Enquiry.find(@lead_id)
    boat = lead.boat

    Rightboat::BoatPdfGenerator.ensure_pdf(boat)

    LeadsMailer.lead_created_notify_buyer(@lead_id).deliver_now

    broker = boat.user
    if %w(nick@popsells.com).include? broker.email
      LeadsMailer.lead_created_notify_pop_yachts(@lead_id).deliver_now
    elsif broker.payment_method_present?
      LeadsMailer.lead_created_notify_broker(@lead_id).deliver_now
    else
      LeadsMailer.lead_created_tease_broker(@lead_id).deliver_now
    end
  end
end
