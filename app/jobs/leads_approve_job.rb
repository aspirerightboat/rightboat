class LeadsApproveJob
  def perform
    deadline = RBConfig[:leads_approve_delay].hours.ago
    Enquiry.pending.joins(:last_lead_trail).where('lead_trails.created_at < ?', deadline).each do |x|
      x.update(status: 'approved')
    end
  end
end
