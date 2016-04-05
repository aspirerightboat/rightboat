class BoatsController < ApplicationController
  before_filter :set_back_link, only: [:show]

  def index
  end

  def manufacturer
    @manufacturer = Manufacturer.find_by(slug: params[:manufacturer])

    if !@manufacturer
      # handle debugging boat urls
      if params[:manufacturer].to_s =~ /rb\d+\z/i
        boat = Boat.find_by(id: Boat.id_from_ref_no(params[:manufacturer]))
        redirect_to makemodel_boat_path(boat) and return if boat
      end

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
    if params[:country] && (country = Country.find_by(slug: params[:country]))
      search_params[:country] = [country.id]
    elsif params[:countries]
      search_params[:country] = params[:countries]
    end

    @boats = Rightboat::BoatSearch.new.do_search(search_params).results

    @model_infos = @manufacturer.models.joins(:boats).where(boats: {status: 'active'})
                       .group('models.id, models.slug, models.name').order('models.name')
                       .pluck('models.id, models.slug, models.name, COUNT(*)')

    @country_infos = Country.joins(:boats).where(boats: {status: 'active', manufacturer_id: @manufacturer.id})
                     .group('countries.id, countries.name, countries.slug').order('countries.name')
                     .pluck('countries.id, countries.name, countries.slug, COUNT(*)')
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
    return if !load_makemodel

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
      return if !load_makemodel
      redirect_to({action: :index}, alert: I18n.t('messages.boat_not_exist')) and return
    end

    store_recent
  end

  def pdf
    @boat = Boat.active.find_by(slug: params[:boat])

    can_view_lead = current_user&.admin? || current_user&.broker? ||
        Enquiry.where(boat_id: @boat.id).where('remote_ip = ? OR user_id = ?', request.remote_ip, current_user.try(:id) || 0).exists?

    if !can_view_lead
      redirect_to("#{makemodel_boat_path(@boat)}#enquiry_popup", alert: I18n.t('messages.not_authorized')) and return
    end

    # UserMailer.boat_detail(current_user.id, @boat.id).deliver_now

    file_path = Rightboat::BoatPdfGenerator.ensure_pdf(@boat)

    send_data File.read(file_path), filename: File.basename(file_path), type: 'application/pdf'
  end

  def filter
    head :bad_request unless request.xhr?

    search_params = {order: current_search_order}
    if params[:models]
      search_params[:model_ids] = model_ids = params[:models].split(',')
      @model_infos = Model.where(id: model_ids).order(:name).pluck(:id, :name)
    end
    if params[:countries]
      search_params[:country] = country_ids = params[:countries].split(',')
      @country_infos = Country.where(id: country_ids).order(:name).pluck(:id, :name)
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

  def load_makemodel
    manufacturer_slug = params[:manufacturer]
    model_slug = params[:model]

    @manufacturer = Manufacturer.find_by(slug: manufacturer_slug)
    redirect_to({action: :index}, alert: 'Manufacturer not found') and return false unless @manufacturer

    @model = Model.find_by(slug: model_slug, manufacturer_id: @manufacturer.id)

    if !@model
      model = OldSlug.models.joins('JOIN models ON models.id = sluggable_id')
                  .where(models: {manufacturer_id: @manufacturer.id}, old_slugs: {slug: model_slug}).first&.model
      if model
        redirect_to(sale_model_path(manufacturer: @manufacturer, model: model)) and return false
      else
        redirect_to(sale_manufacturer_path(manufacturer: @manufacturer), alert: 'Model not found') and return false
      end
    end

    true
  end
end