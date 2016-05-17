class StaffMailer < ApplicationMailer
  default to: 'info@rightboat.com'
  layout 'mailer'

  after_action :gmail_delivery

  def broker_registered_notify_admin(user_id)
    @user = User.find(user_id)
    mail(subject: 'New broker registered – Rightboat')
  end

  def new_private_user(user_id)
    @user = User.find(user_id)
    mail(subject: 'New private user - Rightboat')
  end

  def new_sell_request(boat_id, request_type)
    @boat = Boat.find(boat_id)
    @user = @boat.user
    @request_type = request_type
    mail(subject: 'New sell my boat request - Rightboat')
  end

  def new_berth_enquiry(berth_enquiry_id)
    @berth_enquiry = BerthEnquiry.find(berth_enquiry_id)
    mail(subject: 'New berth enquiry - Rightboat')
  end

  def new_finance(finance_id)
    @finance = Finance.find(finance_id)
    mail(subject: 'New finance - Rightboat')
  end

  def new_insurance(insurance_id)
    @insurance = Insurance.find(insurance_id)
    mail(subject: 'New insurance - Rightboat')
  end

  def suspicious_lead(lead_id, title)
    @lead = Lead.find_by(id: lead_id)
    if @lead
      @boat = @lead.boat
      mail(subject: "#{title} - Rightboat")
    else
      message.perform_deliveries = false
    end
  end

  def lead_quality_check(lead_id)
    @lead = Lead.find(lead_id)
    to_email = RBConfig[:lead_quality_check_email]
    mail(to: to_email, subject: "#{@lead.boat.user.name} wants to review lead ##{@lead.id}")
  end
end
