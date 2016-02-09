class LeadsApproveJob
  def perform
    deadline = RBConfig[:leads_approve_delay].hours.ago
    Enquiry.pending.where('created_at < ?', deadline).find_each { |x| x.update(status: 'approved', updated_at: Time.current) }
  end
end
