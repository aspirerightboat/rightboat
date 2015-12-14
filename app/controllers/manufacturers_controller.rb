class ManufacturersController < ApplicationController
  def index
    @manufacturers = Manufacturer.joins(:boats).group('manufacturers.name, manufacturers.slug')
                         .where('boats.deleted_at IS NULL')
                         .order(:name).page(params[:page]).per(100)
                         .select('manufacturers.name, manufacturers.slug, COUNT(*) AS boats_count')
    @page = params[:page].try(:to_i)
    @page = 1 if !@page || @page <= 0
  end

  def show
    @manufacturer = Manufacturer.find_by(slug: params[:id])
    redirect_to root_path and return if !@manufacturer

    search_params = {
      manufacturer_id: @manufacturer.id,
      page: params[:page] || 1
    }

    search_params[:order] = params[:order] if params[:order].present?
    @boats = Rightboat::BoatSearch.new.do_search(search_params).results
  end

  def by_letter
    @letter = params[:id]
    redirect_to(action: :index) if @letter.blank? || @letter !~ /\A[a-z]\z/

    @manufacturers = Manufacturer.joins(:boats).group('manufacturers.name, manufacturers.slug')
                         .where('manufacturers.name LIKE ?', "#{@letter}%")
                         .where('boats.deleted_at IS NULL')
                         .order(:name).page(params[:page]).per(100)
                         .select('manufacturers.name, manufacturers.slug, COUNT(*) AS boats_count')
  end
end
