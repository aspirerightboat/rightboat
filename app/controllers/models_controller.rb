class ModelsController < ApplicationController
  def index
    redirect_to controller: 'boats', action: 'index'
  end

  def show
    @model = Model.find_by(slug: params[:model]) || OldSlug.models.find_by(slug: params[:model])&.model
    redirect_to(boats_path) and return if !@model

    redirect_to sale_model_path(@model.manufacturer, @model)
  end

  def by_letter
    redirect_to controller: 'boats', action: 'index'
  end
end
