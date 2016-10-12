class Rightboat::LeadsApprover
  def self.approve_recent
    deadline = RBConfig[:leads_approve_delay].hours.ago
    Lead.pending.joins(:last_lead_trail).where('lead_trails.created_at < ?', deadline).each do |x|
      x.update(status: 'approved')
    end
  rescue StandardError => e
    Rightboat::CleverErrorsNotifier.try_notify(e, nil, nil, where: self.class.name)
    raise e
  end
end
