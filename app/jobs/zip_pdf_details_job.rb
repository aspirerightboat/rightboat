class ZipPdfDetailsJob
  attr_accessor :boats_refs, :boats, :job

  def initialize(job_id:, boats_refs: [], user: nil)
    @job = BatchUploadJob.find_by(id: job_id)
    raise 'Job Not Found' unless job

    @boats_refs = boats_refs
    @user = user

    @boats =  boats_refs.map do |ref_no|
      Boat.find_by(id: Boat.id_from_ref_no(ref_no))
    end
  end

  def perform
    # binding.pry

    #   boat = lead.boat
    #
    #   Rightboat::BoatPdfGenerator.ensure_pdf(boat)
    #
    #   LeadsMailer.lead_created_notify_buyer(@lead_id).deliver_now
    #
    #   broker = boat.user
    #   if %w(nick@popsells.com).include? broker.email
    #     LeadsMailer.lead_created_notify_pop_yachts(@lead_id).deliver_later
    #   elsif broker.payment_method_present?
    #     LeadsMailer.lead_created_notify_broker(@lead_id).deliver_later
    #   else
    #     LeadsMailer.lead_created_tease_broker(@lead_id).deliver_later
    #   end
  end
end
