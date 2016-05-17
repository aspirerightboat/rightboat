class LeadsMailer < ApplicationMailer
  default bcc: 'rightboat911716@sugarondemand.com', cc: 'info@rightboat.com'
  add_template_helper BoatsHelper # for pdf
  add_template_helper QrcodeHelper # for pdf
  layout 'mailer'

  after_action :amazon_delivery

  def lead_created_notify_buyer(lead_id)
    @lead = Lead.find(lead_id)
    @boat = @lead.boat
    @office = @boat.office
    attach_boat_pdf

    to_email = STAGING_EMAIL || @lead.email
    mail(to: to_email, subject: "Boat Enquiry ##{@boat.ref_no} - #{@boat.manufacturer} #{@boat.model}")
  end

  def leads_created_notify_buyer(lead_ids, zip_file)
    @leads = Lead.where(id: lead_ids)
    @boats = @leads.map(&:boat)
    @user_name = @leads.first.first_name
    attach_boat_zip(zip_file)

    to_email = STAGING_EMAIL || @leads.first.email
    mail(to: to_email, subject: "Boats Enquiries for #{@boats.count} boats")
  end

  def lead_created_tease_broker(lead_id)
    mail_params = lead_broker_params(lead_id)
    mail(mail_params)
  end

  def lead_created_notify_broker(lead_id)
    mail_params = lead_broker_params(lead_id)
    attach_boat_pdf
    mail(mail_params)
  end

  def lead_created_notify_pop_yachts(lead_id)
    mail_params = lead_broker_params(lead_id)
    mail(mail_params)
  end

  def lead_quality_check(lead_id)
    @lead = Lead.find(lead_id)
    to_email = RBConfig[:lead_quality_check_email]
    mail(to: to_email, subject: "#{@lead.boat.user.name} wants to review lead ##{@lead.id}")
  end

  def invoicing_report(invoice_ids)
    @invoices = Invoice.where(id: invoice_ids).includes(:leads, :user).to_a
    @grand_total = @invoices.map(&:total_ex_vat).sum

    to_email = RBConfig[:invoicing_report_email]
    mail(to: to_email, subject: "Invoicing Report #{Time.current.to_date.to_s(:short)}")
  end

  def invoice_notify_broker(invoice_id)
    @invoice = Invoice.find(invoice_id)
    @broker = @invoice.user
    @broker_info = @broker.broker_info
    @leads = @invoice.leads.includes(:boat).order('id DESC')

    to_email = STAGING_EMAIL # do not send emails to brokers temporarily # STAGING_EMAIL || broker_emails(@broker)
    mail(to: to_email, subject: "Invoice Notification #{Time.current.to_date.to_s(:short)} - Rightboat")
  end

  def lead_reviewed_notify_broker(lead_id)
    @lead = Lead.find(lead_id)

    to_email = STAGING_EMAIL || broker_emails(@lead.boat.user)
    mail(to: to_email, subject: "Lead reviewed notification - #{@lead.name}, ##{@lead.id}")
  end

  private

  def broker_emails(broker)
    ret = [broker.email]
    additional_email = broker.broker_info.try(:additional_email) || []
    ret += additional_email
    ret
  end

  def lead_broker_params(lead_id)
    @lead = Lead.find(lead_id)
    @boat = @lead.boat
    @office = @boat.office

    @broker = @boat.user
    if STAGING_EMAIL
      to_emails = STAGING_EMAIL
    else
      to_emails = []
      office_email = @office.try(:email) || @broker.email
      dist =  @broker.broker_info.lead_email_distribution
      to_emails = broker_emails(@broker) if dist['user']
      to_emails << office_email if dist['office']
      to_emails << 'info@eyb.fr' if dist['eyb']
      to_emails.uniq!
    end

    buyer_name_part = ", #{@lead.name}" if @broker.payment_method_present?
    {to: to_emails, subject: "New enquiry from Rightboat#{buyer_name_part}, Lead ##{@lead.id}"}
  end
end
