class StaffMailerPreview < ActionMailer::Preview

  def broker_registered_notify_admin
    StaffMailer.broker_registered_notify_admin(User.companies.last.id)
  end

  def new_private_user
    StaffMailer.new_private_user(User.last.id)
  end

  def new_berth_enquiry
    StaffMailer.new_berth_enquiry(BerthEnquiry.last.id)
  end

  def new_finance
    StaffMailer.new_finance(Finance.last.id)
  end

  def new_insurance
    StaffMailer.new_insurance(Insurance.last.id)
  end

  def suspicious_lead
    StaffMailer.suspicious_lead(Lead.last.id, 'Multiple leads received – review required')
  end

  def lead_quality_check
    StaffMailer.lead_quality_check(Lead.last.id)
  end

  def broker_added_card
    StaffMailer.broker_added_card(StripeCard.last.user.id)
  end

  def broker_updated_card
    StaffMailer.broker_updated_card(StripeCard.last.user.id)
  end
end
