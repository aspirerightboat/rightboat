class LeadsApproveJob
  def perform
    deadline = RBConfig[:leads_approve_delay].hours.ago
    Enquiry.pending.where('updated_at < ?', deadline).find_each { |x| x.update(status: 'approved') }
  end
end
