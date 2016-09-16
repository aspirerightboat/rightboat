class LeadsMailerPreview < ActionMailer::Preview

  def lead_created_notify_buyer
    LeadsMailer.lead_created_notify_buyer(Lead.last.id)
  end

  def lead_created_tease_broker
    LeadsMailer.lead_created_tease_broker(Lead.last.id)
  end

  def lead_created_notify_broker
    LeadsMailer.lead_created_notify_broker(Lead.last.id)
  end

  def lead_created_notify_pop_yachts
    LeadsMailer.lead_created_notify_pop_yachts(Lead.last.id)
  end

  def invoicing_report
    LeadsMailer.invoicing_report(Invoice.order('id DESC').limit(3).pluck(:id))
  end

  def invoice_notify_broker
    LeadsMailer.invoice_notify_broker(Invoice.last.id)
  end

  def lead_reviewed_notify_broker
    LeadsMailer.lead_reviewed_notify_broker(Lead.where(status: 'cancelled').last.id)
  end
end
