class SearchController < ApplicationController
  before_filter :save_session_settings, only: :results
  before_filter :load_search_facets, only: :results
  after_filter :log_search_terms, only: :results

  def suggestion
    return render(json: []) if params[:q].blank?

    if params[:source_type]
      klass_group = [params[:source_type].to_s.camelize.constantize]
    else
      klass_group = [Manufacturer, Model, Country, FuelType, BoatType]
    end

    search = Sunspot.search(*klass_group) do |q|
      q.with :name_ngrme, params[:q]
    end

    ret = search.results.map do |object|
      object.is_a?(Model) ? object.name_with_manufacturer : object.name
    end

    render json: ret.sort
  end

  def manufacturer_model
    search = Sunspot.search(Manufacturer, Model) do |q|
      if params[:q].blank?
        # all manufacturer_models
        q.order_by(:name)
      else
        q.with :name_ngrme,  params[:q]
      end
    end

    ret = search.results.map do |object|
      object.is_a?(Model) ? object.name_with_manufacturer : object.name
    end

    render json: ret.sort
  end

  def results
    if params[:save_search]
      ctl = Member::SavedSearchesController.new
      ctl.request = request
      ctl.response = response
      ctl.create
      redirect_to member_saved_searches_path, notice: 'Your search was saved'
      return
    end

    params.delete(:page) unless request.xhr?

    search_params = params.clone
    search_params[:order] ||= current_order_field

    search = Rightboat::BoatSearch.new(search_params)
    @boats = search.retrieve_boats
    session[:boats_count] = @boats.total_count

    respond_to do |format|
      format.html
      format.json {
        render json: @boats, serializer: PaginatedSerializer, each_serializer: BoatTemplateSerializer
      }
    end
  end

  private

  def save_session_settings
    # view mode will be working in client side
    # only manage currency, order field and length unit

    if params[:currency].present?
      set_currency(params[:currency])
    end
    if params[:length_unit].present?
      set_length_unit(params[:length_unit])
    end
    if params[:order].present?
      set_order_field(params[:order])
    end
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