class ManufacturersController < ApplicationController
  def index
    unless params[:page]
      @top_manufacturer_infos = Manufacturer.joins(:boats).where(boats: {status: 'active'})
                                    .group('manufacturers.name, manufacturers.slug')
                                    .order('COUNT(*) DESC').limit(60)
                                    .pluck('manufacturers.name, manufacturers.slug, COUNT(*)').sort_by!(&:first)
    end

    @manufacturers = Manufacturer.joins(:boats).where(boats: {status: 'active'})
                         .group('manufacturers.name, manufacturers.slug')
                         .order('manufacturers.name').page(params[:page]).per(100)
                         .select('manufacturers.name, manufacturers.slug, COUNT(*) AS boats_count')

    @page = params[:page].try(:to_i)
    @page = 1 if !@page || @page <= 0
  end

  def show
    @manufacturer = Manufacturer.find_by(slug: params[:id])
    redirect_to root_path and return if !@manufacturer

    params[:manufacturer] = @manufacturer.name # so in advanced search panel manufacturer will be filled

    search_params = {
      manufacturer_id: @manufacturer.id,
      page: params[:page] || 1
    }

    search_params[:order] = params[:order] if params[:order].present?
    @boats = Rightboat::BoatSearch.new.do_search(search_params).results

    @model_infos = @manufacturer.models.joins(:boats).where(boats: {status: 'active'})
                       .group('models.slug, models.name').order(:name)
                       .pluck('models.slug, models.name, COUNT(*)')
  end

  def by_letter
    @letter = params[:id]
    redirect_to(action: :index) if @letter.blank? || @letter !~ /\A[a-z]\z/

    @manufacturers = Manufacturer.joins(:boats).where(boats: {status: 'active'})
                         .where('manufacturers.name LIKE ?', "#{@letter}%")
                         .group('manufacturers.name, manufacturers.slug')
                         .order('manufacturers.name').page(params[:page]).per(100)
                         .select('manufacturers.name, manufacturers.slug, COUNT(*) AS boats_count')
  end
end
