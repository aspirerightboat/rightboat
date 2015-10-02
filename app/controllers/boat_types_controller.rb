class BoatTypesController < ApplicationController
  def index
    @boat_types = BoatType.all
  end

  def show
    @boat_type = BoatType.where(name: params[:id]).first!
    @boats = @boat_type.boats.boat_view_includes.page(params[:page]).per(20)
  end
end