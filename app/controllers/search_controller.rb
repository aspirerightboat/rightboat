class SearchController < ApplicationController
  before_filter :save_session_settings, only: :results
  after_filter :log_search_terms, only: :results

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
    params.delete(:boat_type) if params[:q].present?
    set_current_search_order('score') if params[:q].present? && params[:order].blank?
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

  private

  def save_session_settings
    set_current_currency params[:currency]
    set_current_length_unit(params[:length_unit])
    set_current_search_order(params[:order])
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