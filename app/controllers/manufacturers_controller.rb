class ManufacturersController < ApplicationController
  def index
    @manufacturers = Manufacturer.joins(:boats).group('manufacturers.name, manufacturers.slug')
                         .order('COUNT(*) DESC').page(params[:page]).per(20)
                         .select('manufacturers.name, manufacturers.slug, COUNT(*) AS boats_count')
    @page = params[:page].try(:to_i)
    @page = 1 if !@page || @page <= 0
  end

  def show
    @manufacturer = Manufacturer.where(slug: params[:id]).first!
    @boats = @manufacturer.boats.includes(:currency, :primary_image, :model, :vat_rate, :country).order(:name).page(params[:page]).per(20)
  end

  def by_letter
    @letter = params[:id]
    redirect_to(action: :index) if @letter.blank? || @letter !~ /\A[a-z]\z/

    @manufacturers = Manufacturer.where('name LIKE ?', "#{@letter}%").order(:name).page(params[:page]).per(20)
  end
end
