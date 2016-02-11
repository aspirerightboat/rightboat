class UserMailer < ApplicationMailer
  add_template_helper BoatsHelper
  layout 'mailer'

  def saved_search_updated(user_id, searches)
    @user = User.find(user_id)

    @searches = searches.map { |saved_search_id, boat_ids|
      saved_search = SavedSearch.find_by(id: saved_search_id)
      next if !saved_search
      [saved_search, Boat.where(id: boat_ids).includes(:manufacturer, :model).to_a]
    }.compact

    to_email = STAGING_EMAIL || @user.email
    mail(to: to_email, subject: 'New Search Listings Alert - Rightboat')
  end

  def email_confirmation(user_id)
    @user = User.find(user_id)
    @confirm_href = confirm_email_url(user: user_id, token: @user.confirm_email_token)

    to_email = STAGING_EMAIL || @user.email
    mail(to: to_email, subject: 'Rightboat.com - email verification')
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
      @other_boats = Rightboat::BoatSearch.new.do_search(q: @boat.manufacturer_model, offer_status: 'available', includes: [:user, :currency, :manufacturer, :model, :primary_image, :vat_rate, :country]).results
      @similar_boats = Rightboat::BoatSearch.new.do_search(@boat.similar_options, includes: [:user, :currency, :manufacturer, :model, :primary_image, :vat_rate, :country]).results
    end

    to_email = STAGING_EMAIL || @user.email
    kind = @alert_reason == 'favourite' ? 'Favourite' : 'Enquired'
    mail(to: to_email, subject: "#{kind} boat status changed - #{@boat.manufacturer_model} - Rightboat")
  end

  def new_berth_enquiry(berth_enquiry_id)
    @berth_enquiry = BerthEnquiry.find(berth_enquiry_id)
    mail(to: 'info@rightboat.com', subject: 'New berth enquiry - Rightboat')
  end

  def new_private_user(user_id)
    @user = User.find(user_id)
    mail(to: 'info@rightboat.com', subject: 'New private user - Rightboat')
  end
end