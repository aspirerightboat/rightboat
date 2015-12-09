class BoatTypesController < ApplicationController
  def index
    @boat_types = BoatType.order(:name)
  end

  def show
    @boat_type = BoatType.find_by(name: params[:id])
    redirect_to root_path and return if !@boat_type

    if params[:id] == 'RIB'
      @boats = Rightboat::BoatSearch.new.do_search({q: 'RIB', page: params[:page] || 1}).results
    else
      @boats = @boat_type.boats.not_deleted.boat_view_includes.page(params[:page]).per(30)
    end
  end
end