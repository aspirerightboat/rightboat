class CountriesController < ApplicationController
  def index
    @countries = Country.joins(:boats).group('countries.name, countries.slug')
                     .order('COUNT(*) DESC').page(params[:page]).per(100)
                     .select('countries.name, countries.slug, COUNT(*) AS boats_count')
  end

  def show
    @country = Country.find_by(slug: params[:id])
    redirect_to root_path and return if !@country

    @boats = @country.boats.not_deleted.boat_view_includes.page(params[:page]).per(30)
  end
end
