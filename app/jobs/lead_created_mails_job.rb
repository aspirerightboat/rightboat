class LeadCreatedMailsJob
  def initialize(lead_ids)
    @leads = lead_ids
  end

  def perform
    if @leads.count > 1
      perform_multiple
    else
      perform_single
    end
  end

  private

  def perform_single
    lead = Enquiry.where(id: @leads).first
    boat = lead.boat

    Rightboat::BoatPdfGenerator.ensure_pdf(boat)

    LeadsMailer.lead_created_notify_buyer(lead.id).deliver_now

    notify_broker(boat)
  end

  def perform_multiple
    boats = Enquiry.where(@leads).map(&:boat)

    boats.each do |boat|
      notify_broker(boat)
    end
  end

  def notify_broker(boat)
    broker = boat.user
    if %w(leads@popyachts.com).include? broker.email
      LeadsMailer.lead_created_notify_pop_yachts(@lead_id).deliver_later
    elsif broker.payment_method_present?
      LeadsMailer.lead_created_notify_broker(@lead_id).deliver_later
    else
      LeadsMailer.lead_created_tease_broker(@lead_id).deliver_later
    end
  end
end
