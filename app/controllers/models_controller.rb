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
    @model = Model.find_by(slug: params[:model])
    redirect_to(boats_path) and return if !@model

    redirect_to makemodel_path(@model)
  end

  def by_letter
    @letter = params[:id]
    redirect_to(action: :index) if @letter.blank? || @letter !~ /\A[a-z]\z/

    @models = Model.joins(:boats).group('models.name, models.slug')
                       .where('models.name LIKE ?', "#{@letter}%")
                       .where('boats.deleted_at IS NULL')
                       .order(:name).page(params[:page]).per(100)
                       .select('models.name, models.slug, COUNT(*) AS boats_count')
  end
end