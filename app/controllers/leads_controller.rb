class LeadsController < ApplicationController
  before_action :authenticate_user!, only: [:show, :approve, :quality_check, :define_payment_method]
  before_action :load_lead, only: [:show, :approve, :quality_check]
  before_action :require_broker, only: [:approve, :quality_check, :show]
  before_action :require_broker_payment_method, only: [:show]
  before_action :remember_when_broker_accessed, only: [:show]
  before_action :add_saved_searches_alert_id, only: [:create]

  def create
    if !request.xhr?
      redirect_to root_path, notice: 'Javascript must be enabled' # antispam - bots usually cannot pass simple rails xhr
      return
    end

    if params[:has_account] == 'true' && !current_user
      user = User.find_by(email: params[:email])

      if user && user.valid_password?(params[:password])
        sign_in(user)
        user.remember_me! if params[:remember_me]
      else
        render json: ['Invalid email or password'], root: false, status: 403 and return
      end
    end

    lead = Lead.new(lead_params)
    lead.boat = Boat.find_by(slug: params[:id])
    lead.boat_currency_rate = lead.boat.safe_currency.rate
    lead.user_country_iso = current_user&.user_setting&.country_iso || session[:country]
    lead.mark_if_suspicious(current_user, request.remote_ip)

    if lead.save
      lead.handle_lead_created_mails unless lead.suspicious?

      json = {}
      json[:google_conversion] = render_to_string(partial: 'shared/google_lead_conversion',
                                                  locals: {lead_price: lead.lead_price})
      if current_user
        json[:downloading_popup] = render_to_string(partial: 'shared/lead_downloading_popup',
                                                    locals: {boat: lead.boat})
      else
        json[:signup_popup] = render_to_string(partial: 'shared/lead_signup_popup',
                                               locals: {boat: lead.boat})
      end
      json[:lead_id] = lead.id
      json[:boat_pdf_url] = stream_enquired_pdf_url(lead.id)

      follow_makemodel_of_boats([lead.boat]) if current_user
      UserActivity.create_lead_record(lead_id: lead.id, user: current_user) if current_user

      render json: json
    else
      render json: lead.errors.full_messages, status: 422, root: false
    end
  end

  def create_batch
    if !request.xhr?
      redirect_to root_path, notice: 'Javascript must be enabled' # antispam - bots usually cannot pass simple rails xhr
      return
    end

    if params[:has_account] == 'true' && !current_user && !resolve_user
      render json: ['Invalid email or password'], root: false, status: 403
      return
    end

    boats = fetch_boats
    leads = boats.map do |boat|
      lead = Lead.new(lead_params)
      lead.status = 'batched'
      lead.boat = boat
      lead.boat_currency_rate = boat.safe_currency.rate
      lead.user_country_iso = current_user&.user_setting&.country_iso || session[:country]
      lead.mark_if_suspicious(current_user, request.remote_ip)
      lead
    end

    if leads.all?(&:valid?)
      Lead.transaction do
        leads.each(&:save!)
      end

      if current_user
        follow_makemodel_of_boats(boats)
        leads.each do |lead|
          UserActivity.create_lead_record(lead_id: lead.id, user: current_user)
        end
      end

      render json: batch_create_response_json(leads)
    else
      render json: leads.map { |lead| lead.errors.full_messages }.flatten.uniq, status: 422, root: false
    end
  end

  def show
    @boat = @lead.boat
    @lead_trails = @lead.lead_trails.includes(:user).order('id DESC')
  end

  def approve
    @lead.status = 'approved'
    @lead.save!
    redirect_to({action: :show}, {notice: 'Lead approved'})
  end

  def quality_check
    @lead.status = 'quality_check'
    @lead.assign_attributes(params.require(:lead).permit(:bad_quality_reason, :bad_quality_comment))
    @lead.save! # email should be sent on after_save callback
    redirect_to({action: :show}, {notice: 'Lead will be reviewed by Rightboat staff'})
  end

  def signup_and_view_pdf
    user = User.new(params.permit(:title, :first_name, :last_name, :phone, :email, :password, :password_confirmation))
    user.role = 'PRIVATE'
    user.email_confirmed = true
    user.assign_phone_from_leads

    if user.save
      sign_in(user)
      lead_ids = [params[:lead_id], params[:lead_ids]&.split(',')].flatten.compact
      boat_ids = Lead.where(id: lead_ids).pluck(:boat_id)
      boats = Boat.where(id: boat_ids).to_a
      follow_makemodel_of_boats(boats)
      render json: {google_conversion: render_to_string(partial: 'shared/google_signup_conversion',
                                                        locals: {form_name: 'lead_signup_form'})}
    else
      render json: user.errors.full_messages, root: false, status: 422
    end
  end

  def define_payment_method
  end

  def stream_enquired_pdf
    lead = Lead.find(params[:id])
    boat = lead.boat
    pdf_path = Rightboat::BoatPdfGenerator.ensure_pdf(boat)

    send_file pdf_path
  end

  private

  def resolve_user
    user = User.find_by(email: params[:email])

    if user && user.valid_password?(params[:password])
      sign_in(user)
      user.remember_me! if params[:remember_me]
    end
    user
  end


  def lead_params
    @lead_params ||= params.permit(:title, :first_name, :surname, :email, :country_code, :phone, :message)
      .merge(user_id: current_user.try(:id),
             remote_ip: request.remote_ip,
             browser: request.env['HTTP_USER_AGENT'],
             saved_searches_alert_id: @saved_searches_alert_id&.id)
  end

  def load_lead
    @lead = Lead.find(params[:id])
  end

  def fetch_boats
    boats_ids = params[:boats_ids]&.split(',') || []
    Boat.where(id: boats_ids).includes(:currency, :manufacturer, :model, :country, :vat_rate, :primary_image,
                                       user: [:broker_info, address: :country], office: :address)
  end

  def require_broker
    if !can_view_as_broker(current_user)
      redirect_to root_path, alert: I18n.t('messages.not_authorized')
    end
  end

  def require_broker_payment_method
    if current_user.company? && !current_user.payment_method_present?
      render action: :define_payment_method
    end
  end

  def can_view_as_broker(broker_user)
    current_user.admin? || (broker_user && broker_user.company? && @lead.boat.user == broker_user)
  end

  def can_view_as_buyer(user)
    @lead.user == user
  end

  def remember_when_broker_accessed
    if !@lead.broker_accessed_at && current_user.company?
      @lead.broker_accessed_at = Time.current
      @lead.accessed_by_broker = current_user
      @lead.save!
    end
  end

  def add_saved_searches_alert_id
    if cookies['tracking_token'].present?
      @saved_searches_alert_id = SavedSearchesAlert.find_by(token: cookies[:tracking_token])
    end
  end

  def follow_makemodel_of_boats(boats)
    boats.each { |boat| follow_makemodel(boat.manufacturer_id, boat.model_id) }
  end

  def follow_makemodel(manufacturer_id, model_id)
    SavedSearch.create_and_run(current_user, manufacturers: [manufacturer_id.to_s], models: [model_id.to_s])
  end

  def batch_create_response_json(leads)
    google_conversions = ''

    job = BatchUploadJob.create
    ZipPdfDetailsJob.new(job: job, boats: fetch_boats, leads: leads).perform
    json = job.as_json
    if !current_user
      json[:signup_popup] = render_to_string(partial: 'shared/leads_signup_popup')
    end
    json[:title] = lead_params[:title]
    json[:first_name] = lead_params[:first_name]
    json[:last_name] = lead_params[:surname]
    json[:email] = lead_params[:email]
    json[:full_phone_number] = lead_params[:country_code].to_s + lead_params[:phone].to_s
    json[:has_account] = User.find_by(email: params[:email]).present?
    json[:lead_ids] = leads.map(&:id)
    leads.each do |lead|
      google_conversions << render_to_string(partial: 'shared/google_lead_conversion',
                                             locals: {lead_price: lead.lead_price})
    end
    json[:google_conversion] = google_conversions
    json
  end

end
