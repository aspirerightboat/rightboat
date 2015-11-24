class BoatTypesController < ApplicationController
  def index
    @boat_types = BoatType.order(:name)
  end

  def show
    @boat_type = BoatType.find_by(name: params[:id])
    redirect_to root_path and return if !@boat_type

    @boats = @boat_type.boats.not_deleted.boat_view_includes.page(params[:page]).per(20)
  end
end