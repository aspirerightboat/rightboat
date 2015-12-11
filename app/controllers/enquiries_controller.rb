class EnquiriesController < ApplicationController
  before_action :authenticate_user!, except: [:create, :signup_and_view_pdf]
  before_action :load_enquiry, only: [:show, :approve, :quality_check]
  before_action :require_broker, only: [:approve, :quality_check]
  before_action :require_buyer_or_broker, only: [:show]
  before_action :remember_when_broker_accessed, only: [:show]

  def create
    # disable captcha for easy use
    # if !Rightboat::Captcha.correct?(session[:captcha].with_indifferent_access, params[:enquiry][:captcha])
    #   enquiry.captcha_correct = false
    # end
    if !request.xhr?
      redirect_to root_path, notice: 'Javascript must be enabled' # antispam - bots usually cannot pass simple rails xhr
    end

    if params[:password].present? && !current_user
      user = User.find_by(email: params[:email])

      if user && user.valid_password?(params[:password])
        sign_in(user)
        user.remember_me! if params[:remember_me]
      else
        render json: ['Invalid email or password'], root: false, status: 403 and return
      end
    end

    enquiry = Enquiry.new(enquiry_params)

    enquiry.boat = Boat.find_by(slug: params[:id])
    if enquiry.save
      # session.delete(:captcha)
      LeadsMailer.lead_created_notify_buyer(enquiry.id).deliver_later
      if enquiry.boat.user.email == 'nick@popsells.com'
        LeadsMailer.lead_created_notify_pop_yachts(enquiry.id).deliver_later
      else
        LeadsMailer.lead_created_notify_broker(enquiry.id).deliver_later
      end
      enquiry.create_lead_trail(true)

      render json: current_user ? {location: member_enquiries_path} : {show_result_popup: true}
    else
      # session[:captcha] = Rightboat::Captcha.generate
      render json: enquiry.errors.full_messages, status: 422, root: false
    end
  end

  def show
    @boat = @enquiry.boat
    @lead_trails = @enquiry.lead_trails.includes(:user).order('id DESC')
  end

  def approve
    @enquiry.status = 'approved'
    @enquiry.save!
    redirect_to({action: :show}, {notice: 'Lead approved'})
  end

  def quality_check
    @enquiry.status = 'quality_check'
    @enquiry.assign_attributes(params.require(:enquiry).permit(:bad_quality_reason, :bad_quality_comment))
    @enquiry.save! # email should be sent on after_save callback
    redirect_to({action: :show}, {notice: 'Lead will be reviewed by Rightboat staff'})
  end

  def signup_and_view_pdf
    user = User.new(params.permit(:title, :first_name, :last_name, :email, :password, :password_confirmation))
    user.role = 'PRIVATE'
    user.email_confirmed = true

    if user.save
      sign_in(user)
      render json: {location: member_enquiries_path}
    else
      render json: user.errors.full_messages, root: false, status: 422
    end
  end

  private

  def enquiry_params
    params.permit(:title, :first_name, :surname, :email, :country_code, :phone, :message)
          .merge({user_id: current_user.try(:id), remote_ip: request.remote_ip, browser: request.env['HTTP_USER_AGENT']})
  end

  def load_enquiry
    @enquiry = Enquiry.find(params[:id])
  end

  def require_broker
    if !can_view_as_broker(current_user)
      redirect_to root_path, alert: I18n.t('messages.not_authorized')
    end
  end

  def require_buyer_or_broker
    if !can_view_as_broker(current_user) && !can_view_as_buyer(current_user)
      redirect_to root_path, alert: I18n.t('messages.not_authorized')
    end
  end

  def can_view_as_broker(broker_user)
    broker_user && broker_user.company? && @enquiry.boat.user == broker_user
  end

  def can_view_as_buyer(user)
    @enquiry.user == user
  end

  def remember_when_broker_accessed
    if !@enquiry.broker_accessed_at && current_user.company?
      @enquiry.broker_accessed_at = Time.current
      @enquiry.accessed_by_broker = current_user
      @enquiry.save!
    end
  end
end
