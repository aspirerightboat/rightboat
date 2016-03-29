class BoatsController < ApplicationController
  before_filter :set_back_link, only: [:show]

  def index
  end

  def manufacturer
    @manufacturer = Manufacturer.find_by(slug: params[:manufacturer])

    if !@manufacturer
      # handle old boat urls
      boat = OldSlug.boats.find_by(slug: params[:manufacturer])&.boat
      redirect_to makemodel_boat_path(boat) and return if boat
    end

    redirect_to(action: :index) and return if !@manufacturer

    params[:manufacturer] = @manufacturer.name # so in advanced search panel manufacturer will be filled

    search_params = {
        manufacturer_id: @manufacturer.id,
        page: params[:page] || 1
    }

    search_params[:order] = params[:order] if params[:order].present?
    @boats = Rightboat::BoatSearch.new.do_search(search_params).results

    @model_infos = @manufacturer.models.joins(:boats, :manufacturer).where(boats: {status: 'active'})
                       .group('models.id, models.slug, models.name, manufacturers.slug').order(:name)
                       .pluck('models.id, models.slug, models.name, manufacturers.slug, COUNT(*)')
  end

  def manufacturers_by_letter
    @letter = params[:letter]
    redirect_to(action: :index) if @letter.blank? || @letter !~ /\A[a-z]\z/

    @manufacturers = Manufacturer.joins(:boats).where(boats: {status: 'active'})
                         .where('manufacturers.name LIKE ?', "#{@letter}%")
                         .group('manufacturers.name, manufacturers.slug')
                         .order('manufacturers.name')
                         .select('manufacturers.name, manufacturers.slug, COUNT(*) AS boats_count')
  end

  def model
    @model = Model.find_by(slug: params[:model])
    redirect_to(action: :index) and return if !@model

    params[:model] = @model.name
    params[:manufacturer] = @model.manufacturer.name

    search_params = {
        model_id: @model.id,
        page: params[:page] || 1
    }

    search_params[:order] = params[:order] if params[:order].present?
    @boats = Rightboat::BoatSearch.new.do_search(search_params).results

    @manufacturer = @model.manufacturer
  end

  def show
    @boat = Boat.active.find_by(slug: params[:boat]) if params[:boat].present?
    @boat = OldSlug.boats.find_by(slug: params[:boat])&.boat if !@boat

    if !@boat
      if (model = Model.find_by(slug: params[:model]))
        path = makemodel_path(model)
      elsif (manufacturer = Manufacturer.find_by(slug: params[:manufacturer]))
        path = make_path(manufacturer)
      else
        path = {action: :index}
      end
      redirect_to(path, alert: I18n.t('messages.boat_not_exist')) and return
    end

    store_recent
  end

  def pdf
    @boat = Boat.active.find_by(slug: params[:boat])

    can_view_lead = current_user.try(:admin?) ||
        Enquiry.where(boat_id: @boat.id).where('remote_ip = ? OR user_id = ?', request.remote_ip, current_user.try(:id) || 0).exists?

    if !can_view_lead
      redirect_to("#{makemodel_boat_path(@boat)}#enquiry_popup", alert: I18n.t('messages.not_authorized')) and return
    end

    UserMailer.boat_detail(current_user.id, @boat.id).deliver_now

    render pdf: 'pdf',
           layout: 'pdf',
           margin: { bottom: 16 },
           footer: {
               html: {
                   template:  'shared/_pdf_footer.html.haml',
                   layout:    'pdf'
               }
           }

  end

  def filter
    head :bad_request unless request.xhr?

    search_params = {order: current_search_order}

    if params[:model_ids]
      search_params[:model_ids] = params[:model_ids].to_s.split(',')
    end

    @boats = Rightboat::BoatSearch.new.do_search(search_params).results
  end

  private

  def set_back_link
    if request.referer =~ /^([^\?]+)?\/search(\?.*)?$/
      @back_url = request.referer.to_s
    end
  end

  def store_recent
    attrs = { target_id: @boat.id, action: :show, ip: request.remote_ip }

    if (activity = Activity.where(attrs).first)
      activity.update(count: activity.count + 1)
    else
      Activity.create(attrs.merge(user_id: current_user.try(:id)))
    end
  end
end