class LeadsApproveJob
  def perform
    deadline = RBConfig.get('leads_approve_delay').to_i.hours.ago
    Enquiry.where(status: 'pending').where('created_at < ?', deadline).update_all(status: 'approved')
  end
end
