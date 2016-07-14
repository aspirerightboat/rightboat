class LeadCreatedMailsJob
  include Rightboat::DelayedJobNotifyOnError

  def initialize(lead_ids)
    @lead_ids = lead_ids
  end

  def perform
    if @lead_ids.one?
      perform_one
    else
      perform_many
    end
  end

  private

  def perform_one
    lead = Lead.find(@lead_ids.first)
    Rightboat::BoatPdfGenerator.ensure_pdf(lead.boat)

    LeadsMailer.lead_created_notify_buyer(lead.id).deliver_now

    notify_broker(lead)
  end

  def perform_many
    leads = Lead.includes(boat: :user).find(@lead_ids)

    leads.each do |lead|
      notify_broker(lead)
    end
  end

  def notify_broker(lead)
    broker = lead.boat.user
    if %w(leads@popyachts.com).include? broker.email
      LeadsMailer.lead_created_notify_pop_yachts(lead.id).deliver_later
    elsif broker.payment_method_present?
      LeadsMailer.lead_created_notify_broker(lead.id).deliver_later
    else
      LeadsMailer.lead_created_tease_broker(lead.id).deliver_later
    end
  end
end
