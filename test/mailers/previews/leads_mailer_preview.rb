class LeadsMailerPreview < ActionMailer::Preview

  def lead_created_notify_buyer
    LeadsMailer.lead_created_notify_buyer(Enquiry.last.id)
  end

  def lead_created_tease_broker
    LeadsMailer.lead_created_tease_broker(Enquiry.last.id)
  end

  def lead_created_notify_broker
    LeadsMailer.lead_created_notify_broker(Enquiry.last.id)
  end

  def lead_created_notify_pop_yachts
    LeadsMailer.lead_created_notify_pop_yachts(Enquiry.last.id)
  end

  def lead_quality_check
    LeadsMailer.lead_quality_check(Enquiry.last.id)
  end

  def invoicing_report
    LeadsMailer.invoicing_report([Invoice.last.id])
  end

  def invoice_notify_broker
    LeadsMailer.invoice_notify_broker(Invoice.last.id)
  end

  def lead_reviewed_notify_broker
    LeadsMailer.lead_reviewed_notify_broker(Enquiry.last.id)
  end
end
