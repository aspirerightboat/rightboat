class ModelsController < ApplicationController
  def index
    @models = Model.order(:name).page(params[:page]).per(20)
  end

  def show
    @model = Model.where(slug: params[:id]).first!
    @boats = @model.manufacturer.boats.boat_view_includes.page(params[:page]).per(20)
  end
end