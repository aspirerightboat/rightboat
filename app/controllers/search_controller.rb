class SearchController < ApplicationController
  before_action :save_session_settings, only: :results

  def manufacturers
    render json: {items: Manufacturer.solr_suggest_by_term(params[:q])}
  end

  def models
    manufacturer_ids = if params[:manufacturer]
                         [Manufacturer.find_by(name: params[:manufacturer])&.id].compact
                       elsif params[:manufacturer_ids]
                         params[:manufacturer_ids].to_s.split(/,|-/)
                       elsif params[:manufacturer_id]
                         [params[:manufacturer_id]]
                       end
    models = manufacturer_ids.any? ? Model.solr_suggest_by_term(params[:q], manufacturer_ids) : []
    render json: {items: models}
  end

  def results
    return if show_catalog_if_q_manufacturer

    params.delete(:page) unless request.xhr?
    set_current_search_order(params[:q].present? ? 'score_desc' : 'price_desc') if params[:order].blank?
    params[:order] ||= current_search_order

    @search_params = Rightboat::SearchParams.new(params).read
    @boats = Rightboat::BoatSearch.new.do_search(search_params: @search_params).results
    session[:boats_count] = @boats.total_count
    @prev_url = request.referrer['boats-for-sale'] if request.referer

    if @boats.any? && @boats.size <= 6
      similar_opts = @boats.first.similar_options
      @similar_boats = Rightboat::BoatSearch.new.do_search(search_params: @search_params, per_page: 6).results
      @similar_boats -= @boats
    end

    respond_to do |format|
      format.html
      format.json {
        render json: @boats, serializer: PaginatedSerializer, each_serializer: BoatTemplateSerializer
      }
    end
  end

  def engine_manufacturers
    items = EngineManufacturer.where('name LIKE ?', "#{params[:q]}%").order(:name).limit(30).pluck_h(:id, :name)
    render json: {items: items}
  end

  def engine_models
    manufacturer_id = if params[:engine_manufacturer]
                        EngineManufacturer.find_by(name: params[:engine_manufacturer])&.id
                      elsif params[:engine_manufacturer_id]
                        params[:engine_manufacturer_id]
                      end
    items = EngineModel.where(engine_manufacturer_id: manufacturer_id).where('name LIKE ?', "#{params[:q]}%")
                .order(:name).limit(30).pluck_h(:id, :name)
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

  def show_catalog_if_q_manufacturer
    if params[:q].present? &&
        params[:manufacturers].blank? &&
        params[:models].blank? &&
        (m = Manufacturer.find_by(name: params[:q].strip.downcase))
      redirect_to sale_manufacturer_path(m)
    end
  end

  def save_session_settings
    set_current_currency params[:currency]
    set_current_length_unit(params[:length_unit])
    set_current_search_order(params[:order])
    update_user_settings
  end

end
