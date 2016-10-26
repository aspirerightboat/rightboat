class LeadCreatedMailsJob
  include Rightboat::DelayedJobNotifyOnError

  def initialize(lead_id)
    @lead_id = lead_id
  end

  def perform
    lead = Lead.find(@lead_id)
    Rightboat::BoatPdfGenerator.ensure_pdf(lead.boat)

    LeadsMailer.lead_created_notify_buyer(lead.id).deliver_now

    notify_broker(lead)
  end

  private

  def notify_broker(lead)
    broker = lead.boat.user
    if %w(leads@popyachts.com).include? broker.email
      LeadsMailer.lead_created_notify_pop_yachts(lead.id).deliver_later
    elsif broker.lead_emails_active?
      LeadsMailer.lead_created_notify_broker(lead.id).deliver_later
    else
      LeadsMailer.lead_created_tease_broker(lead.id).deliver_later
    end
  end
end
