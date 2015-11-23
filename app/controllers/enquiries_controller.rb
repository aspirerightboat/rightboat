class EnquiriesController < ApplicationController
  before_action :authenticate_user!, except: [:create]
  before_action :load_enquiry, only: [:show, :approve, :quality_check]
  before_action :require_broker, only: [:approve, :quality_check]
  before_action :require_buyer_or_broker, only: [:show]
  before_action :remember_when_broker_accessed, only: [:show]

  protect_from_forgery except: :create # temporary fix for "Can't verify CSRF token authenticity" error on prod

  def create
    enquiry = Enquiry.new(enquiry_params)

    # disable captcha for easy use
    # if !Rightboat::Captcha.correct?(session[:captcha].with_indifferent_access, params[:enquiry][:captcha])
    #   enquiry.captcha_correct = false
    # end

    enquiry.boat = Boat.find(params[:boat_id])
    if enquiry.save
      sign_in(enquiry.user) if enquiry.have_account
      # session.delete(:captcha)
      LeadsMailer.lead_created_notify_buyer(enquiry.id).deliver_later
      if enquiry.boat.user.email == 'nick@popsells.com'
        LeadsMailer.lead_created_notify_pop_yachts(enquiry.id).deliver_later
      else
        LeadsMailer.lead_created_notify_broker(enquiry.id).deliver_later
      end
      enquiry.create_lead_trail(true)
      render json: enquiry, serializer: EnquirySerializer, root: false
    else
      # session[:captcha] = Rightboat::Captcha.generate
      render json: enquiry, serializer: ErrorSerializer, status: :unprocessable_entity, root: false
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

  private

  def enquiry_params
    params.require(:enquiry)
          .permit(:title, :first_name, :surname, :email, :country_code, :phone, :message, :have_account, :password, :honeypot)
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
