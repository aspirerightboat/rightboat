class CountriesController < ApplicationController
  def index
    @countries = Country.joins(:boats).group('countries.name, countries.slug')
                     .where('boats.deleted_at IS NULL')
                     .order('COUNT(*) DESC').page(params[:page]).per(100)
                     .select('countries.name, countries.slug, COUNT(*) AS boats_count')
  end

  def show
    @country = Country.find_by(slug: params[:id])
    redirect_to root_path and return if !@country

    search_params = {
      country_id: @country.id,
      page: params[:page] || 1
    }

    search_params[:order] = params[:order] if params[:order].present?
    @boats = Rightboat::BoatSearch.new.do_search(search_params).results
  end
end
