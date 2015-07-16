class SearchController < ApplicationController
  before_filter :save_session_settings, only: :results
  before_filter :load_search_facets, only: :results

  def tags
    render json: Currency.all.map(&:name)
  end

  def suggestion
    return render(json: []) if params[:q].blank?

    if params[:source_type]
      klass_group = [params[:source_type].to_s.camelize.constantize]
    else
      klass_group = [Manufacturer, Model, Country, FuelType, BoatType]
    end

    search = Sunspot.search(*klass_group) do |q|
      q.with :live, true
      q.with :name_ngrme, params[:q]
    end
    ret = search.results.map do |object|
      object.is_a?(Model) ? object.full_name : object.name
    end

    render json: ret
  end

  def manufacturer_model
    search = Sunspot.search(Manufacturer, Model) do |q|
      q.with :live, true
      if params[:q].blank?
        # all manufacturer_models
        q.order_by(:name)
      else
        q.with :name_ngrme,  params[:q]
      end
    end

    json = search.results.map do |object|
      object.is_a?(Manufacturer) ? object.name : object.full_name
    end
    render json: json
  end

  def results
    params.delete(:page) unless request.xhr?

    search_params = params.clone
    search_params[:order] ||= current_order_field

    search = Rightboat::BoatSearch.new(search_params)
    @boats = search.retrieve_boats

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

    if !params[:currency].blank?
      currency = Currency.find_by_name(params[:currency]) rescue nil
      set_currency(currency)
    elsif !params[:length_unit].blank?
      set_length_unit(params[:length_unit])
    elsif !params[:order].blank?
      set_order_field(params[:order])
    end
  end
end