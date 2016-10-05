class BoatsController < ApplicationController
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

    params[:order] ? set_current_search_order(params[:order]) : params[:order] = current_search_order
    boat_search = Rightboat::BoatSearch.new.do_search(params: params, with_facets: true)
    @boats = boat_search.results
    @total_count = @boats.total_count

    @filters_data = Rightboat::SearchFiltersData.new(@manufacturer, boat_search).fetch

    @model_filter_tags = Model.where(id: boat_search.sp.model_ids).order(:name).pluck(:id, :name) if boat_search.sp.model_ids
    @country_filter_tags = Country.where(id: boat_search.sp.country_ids).order(:name).pluck(:id, :name) if boat_search.sp.country_ids
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

    fixed_params = {
        model_id: @model.id,
        page: params[:page],
        order: params[:order]
    }
    @boats = Rightboat::BoatSearch.new.do_search(params: fixed_params).results
  end

  def show
    @boat = Boat.find_by(slug: params[:boat]) if params[:boat].present?
    @boat = OldSlug.boats.find_by(slug: params[:boat])&.boat if !@boat

    if !@boat || !@boat.active? && @boat.user != current_user
      return if !load_makemodel
      redirect_to({action: :index}, alert: I18n.t('messages.boat_not_exist')) and return
    end

    @came_from = case request.referer
                 when %r{/search\?} then :search
                 when %r{/boats-for-sale/} then :boats_for_sale
                 end
    @back_url = request.referer if @came_from

    UserActivity.create_boat_visit(boat_id: @boat.id, user: current_user)
    store_recent
  end

  def pdf
    @boat = Boat.active.find_by(slug: params[:boat])

    can_view_lead = current_user&.admin? || current_user&.broker? ||
        Lead.where(boat_id: @boat.id).where('remote_ip = ? OR user_id = ?', request.remote_ip, current_user.try(:id) || 0).exists?

    if !can_view_lead
      redirect_to("#{makemodel_boat_path(@boat)}#lead_popup", alert: I18n.t('messages.not_authorized')) and return
    end

    # UserMailer.boat_detail(current_user.id, @boat.id).deliver_now

    if @boat.blank?
      redirect_to({action: :index}, alert: I18n.t('messages.boat_not_exist')) and return
    end

    file_path = Rightboat::BoatPdfGenerator.ensure_pdf(@boat)

    send_data File.read(file_path), filename: File.basename(file_path), type: 'application/pdf'
  end

  def store_recent
    recently_viewed_boat_ids = [@boat.id]
    if cookies[:recently_viewed_boat_ids]
      recently_viewed_boat_ids += cookies[:recently_viewed_boat_ids].split(',')
    end
    cookies[:recently_viewed_boat_ids] = recently_viewed_boat_ids.uniq[0..2].join(',')
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
