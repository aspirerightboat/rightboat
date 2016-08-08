class SearchController < ApplicationController
  before_filter :save_session_settings, only: :results
  after_filter :log_search_terms, only: :results

  def manufacturers
    render json: {items: Manufacturer.solr_suggest_by_term(params[:q])}
  end

  def models
    manufacturer_ids = if params[:manufacturer]
                         [Manufacturer.find_by(name: params[:manufacturer])&.id].compact
                       elsif params[:manufacturer_ids]
                         params[:manufacturer_ids].to_s.split(/,|-/)
                       end
    models = manufacturer_ids.any? ? Model.solr_suggest_by_term(params[:q], manufacturer_ids) : []
    render json: {items: models}
  end

  def results
    if params[:q].present? && (boat = find_makemodel_boat(params[:q].downcase))
      if boat.manufacturer.name.downcase == params[:q].strip.downcase
        redirect_to sale_manufacturer_path(manufacturer: boat.manufacturer) and return
      else
        redirect_to sale_manufacturer_path(manufacturer: boat.manufacturer, models: boat.model_id) and return
      end
    end

    params.delete(:page) unless request.xhr?
    set_current_search_order(params[:q].present? ? 'score_desc' : 'price_desc') if params[:order].blank?
    params[:order] ||= current_search_order

    boat_search = Rightboat::BoatSearch.new.do_search(params, with_facets: true)
    @boats = boat_search.results
    @search_facets = boat_search.facets_data
    session[:boats_count] = @boats.total_count
    @prev_url = request.referrer['boats-for-sale'] if request.referer

    respond_to do |format|
      format.html
      format.json {
        render json: @boats, serializer: PaginatedSerializer, each_serializer: BoatTemplateSerializer
      }
    end
  end

  def engine_manufacturers
    items = EngineManufacturer.where('name LIKE ?', "#{params[:q]}%").order(:name).limit(30).pluck_h(:name)
    render json: {items: items}
  end

  def engine_models
    manufacturer = (EngineManufacturer.find_by(name: params[:engine_manufacturer]) if params[:engine_manufacturer])
    items = EngineModel.where(engine_manufacturer: manufacturer).where('name LIKE ?', "#{params[:q]}%")
                .order(:name).limit(30).pluck_h(:name)
    render json: {items: items}
  end

  def hull_materials
    render json: {items: distinct_spec_values('hull_material', params[:q])}
  end

  def keel_types
    render json: {items: distinct_spec_values(%w(keel keel_type), params[:q])}
  end

  def fuel_types
    items = FuelType.where('name LIKE ?', "#{params[:q]}%").order(:name).limit(30).pluck_h(:name)
    render json: {items: items}
  end

  def countries
    items = Country.where('name LIKE ?', "#{params[:q]}%").order(:name).limit(30).pluck_h(:name)
    render json: {items: items}
  end

  def locations
    country = (Country.where(name: params[:country]) if params[:country])
    items = Boat.where(country: country).where('location LIKE ?', "#{params[:q]}%")
                .order(:location).limit(30).pluck('DISTINCT location')
                .map { |loc| {name: loc} }
    render json: {items: items}
  end

  def drive_types
    items = DriveType.where('name LIKE ?', "#{params[:q]}%").order(:name).limit(30).pluck_h(:name)
    render json: {items: items}
  end

  private

  def distinct_spec_values(spec_name, q)
    spec = Specification.find_by(name: spec_name)
    BoatSpecification.where(specification: spec).where('value LIKE ?', "#{q}%").order(:value).limit(30)
        .pluck('DISTINCT value').map { |v| {name: v} }
  end

  def find_makemodel_boat(q)
    search = Boat.retryable_solr_search! do
      with :live, true
      paginate page: 1, per_page: 1
      any_of do
        with :manufacturer, q
        with :manufacturer_model, q
      end
    end

    search.results.first
  end

  def save_session_settings
    set_current_currency params[:currency]
    set_current_length_unit(params[:length_unit])
    set_current_search_order(params[:order])
    update_user_settings
  end

  def log_search_terms
    attrs = params.except(:utf8, :controller, :action, :button)
    return if attrs.values.all?(&:blank?)

    if (activity = Activity.search.where(parameters: attrs).first)
      activity.inc(count: 1)
    else
      Activity.create(parameters: attrs, action: :search)
    end
  end
end
