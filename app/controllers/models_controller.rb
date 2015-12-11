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

    search_params = {
      model_id: @model.id,
      page: params[:page] || 1
    }

    search_params[:order] = params[:order] if params[:order].present?
    @boats = Rightboat::BoatSearch.new.do_search(search_params).results
  end
end