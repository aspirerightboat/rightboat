class BoatTypesController < ApplicationController
  def index
    @boat_types = BoatType.order(:name)
  end

  def show
    @boat_type = BoatType.find_by(name: params[:id])
    redirect_to root_path and return if !@boat_type

    search_params = if params[:id] == 'RIB'
                      { q: 'RIB' }
                    else
                      { boat_type_id: @boat_type.id }
                    end

    search_params[:order] = params[:order] if params[:order].present?
    search_params[:page] = params[:page] || 1
    @boats = Rightboat::BoatSearch.new.do_search(search_params).results
  end
end