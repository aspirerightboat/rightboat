class ModelsController < ApplicationController
  def index
    @models = Model.joins(:boats).group('models.name, models.slug')
                       .where('boats.deleted_at IS NULL')
                       .order(:name).page(params[:page]).per(100)
                       .select('models.name, models.slug, COUNT(*) AS boats_count')
    @page = params[:page].try(:to_i)
    @page = 1 if !@page || @page <= 0
  end

  def show
    @model = Model.find_by(slug: params[:id])
    redirect_to root_path and return if !@model

    @boats = @model.manufacturer.boats.not_deleted.boat_view_includes.page(params[:page]).per(20)
  end
end