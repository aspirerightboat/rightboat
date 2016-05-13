class LeadsApproveJob
  def perform
    deadline = RBConfig[:leads_approve_delay].hours.ago
    Enquiry.pending.joins(:last_lead_trail).where('lead_trails.created_at < ?', deadline).each do |x|
      x.update(status: 'approved')
    end
  rescue StandardError => e
    Rightboat::CleverErrorsNotifier.try_notify(e, nil, nil, job: 'LeadsApproveJob')
    raise e
  end
end
