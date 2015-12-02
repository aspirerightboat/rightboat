class LeadsApproveJob
  def perform
    deadline = RBConfig[:leads_approve_delay].hours.ago
    Enquiry.where(status: 'pending').where('created_at < ?', deadline).update_all(status: 'approved', updated_at: Time.now)
  end
end
