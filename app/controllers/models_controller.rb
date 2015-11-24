class ModelsController < ApplicationController
  def index
    @models = Model.order(:name).page(params[:page]).per(20)
  end

  def show
    @model = Model.find_by(slug: params[:id])
    redirect_to root_path and return if !@model

    @boats = @model.manufacturer.boats.not_deleted.boat_view_includes.page(params[:page]).per(20)
  end
end