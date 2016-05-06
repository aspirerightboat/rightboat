class UserMailer < ApplicationMailer
  add_template_helper BoatsHelper
  add_template_helper QrcodeHelper
  add_template_helper SavedSearchesMailerHelper
  add_template_helper MakemodelLinksHelper
  layout 'mailer'

  def saved_search_updated(user_id, searches, saved_searches_alert_id)
    @user = User.find(user_id)
    @saved_searches_alert = SavedSearchesAlert.find(saved_searches_alert_id)
    saved_search_ids = []
    @searches = searches.map { |saved_search_id, boat_ids|
      saved_search = SavedSearch.find_by(id: saved_search_id)
      next if !saved_search
      saved_search_ids << saved_search_id
      [saved_search, Boat.where(id: boat_ids).includes(:manufacturer, :model, :primary_image, :currency, :vat_rate, :country).to_a]
    }.compact

    @utm_params = {
        content: "#{self.class.name}-#{action_name}",
        campaign: 'saved_searches',
        sent_at: Time.current.to_date.to_s(:db)
    }

    to_email = STAGING_EMAIL || @user.email
    mail(to: to_email, subject: 'New Search Listings Alert - Rightboat')
  end

  def email_confirmation(user_id)
    @user = User.find(user_id)
    @confirm_href = confirm_email_url(user: user_id, token: @user.confirm_email_token)

    to_email = STAGING_EMAIL || @user.email
    mail(to: to_email, subject: 'Email Verification – Rightboat')
  end

  def broker_registered(user_id)
    @user = User.find(user_id)
    @confirm_href = confirm_email_url(user: user_id, token: @user.confirm_email_token)

    to_email = STAGING_EMAIL || @user.email
    mail(to: to_email, subject: 'Welcome Broker – Rightboat')
  end

  def broker_registered_notify_admin(user_id)
    @user = User.find(user_id)

    mail(to: 'info@rightboat.com', subject: 'New broker registered – Rightboat')
  end

  def new_sell_request(boat_id, request_type)
    @boat = Boat.find(boat_id)
    @user = @boat.user
    @request_type = request_type

    mail(to: 'info@rightboat.com', subject: 'New sell my boat request - Rightboat')
  end

  def boat_status_changed(user_id, boat_id, reason, alert_reason)
    @user = User.find(user_id)
    @boat = Boat.find(boat_id)
    @reason = reason
    @alert_reason = alert_reason
    if @reason == 'deleted'
      @other_boats = Rightboat::BoatSearch.new.do_search(manufacturer: @boat.manufacturer.name, model: @boat.model.name, exclude_ref_no: @boat.ref_no, includes: [:user, :currency, :manufacturer, :model, :primary_image, :vat_rate, :country]).results
      @similar_boats = Rightboat::BoatSearch.new.do_search(@boat.similar_options, includes: [:user, :currency, :manufacturer, :model, :primary_image, :vat_rate, :country]).results
    end

    to_email = STAGING_EMAIL || @user.email
    kind = @alert_reason == 'favourite' ? 'Favourite' : 'Enquired'
    mail(to: to_email, subject: "#{kind} boat status changed - #{@boat.manufacturer_model} - Rightboat")
  end

  def boat_detail(user_id, boat_id)
    @user = User.find(user_id)
    @boat = Boat.find(boat_id)
    attach_boat_pdf

    to_email = STAGING_EMAIL || @user.email
    mail(to: to_email, subject: "Boat Detail ##{@boat.ref_no} - #{@boat.manufacturer} #{@boat.model}")
  end


  def new_berth_enquiry(berth_enquiry_id)
    @berth_enquiry = BerthEnquiry.find(berth_enquiry_id)
    mail(to: 'info@rightboat.com', subject: 'New berth enquiry - Rightboat')
  end

  def new_finance(finance_id)
    @finance = Finance.find(finance_id)
    mail(to: 'info@rightboat.com', subject: 'New finance - Rightboat')
  end

  def new_insurance(insurance_id)
    @insurance = Insurance.find(insurance_id)
    mail(to: 'info@rightboat.com', subject: 'New insurance - Rightboat')
  end

  def new_private_user(user_id)
    @user = User.find(user_id)
    mail(to: 'info@rightboat.com', subject: 'New private user - Rightboat')
  end
end
