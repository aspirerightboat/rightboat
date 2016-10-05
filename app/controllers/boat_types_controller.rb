class BoatTypesController < ApplicationController
  def index
    redirect_to controller: 'boats', action: 'index'
  end

  def show
    @boat_type = BoatType.find_by(slug: params[:id])
    redirect_to root_path and return if !@boat_type

    fixed_params = params.slice(:order, :page).merge(
        params[:id] == 'RIB' ? {q: 'RIB'} : {boat_type_id: @boat_type.id}
    )
    @boats = Rightboat::BoatSearch.new.do_search(params: fixed_params).results
  end
end
