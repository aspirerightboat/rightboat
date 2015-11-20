class CountriesController < ApplicationController
  def index
    @countries = Country.joins(:boats).group('countries.name, countries.slug')
                     .order('COUNT(*) DESC').page(params[:page]).per(20)
                     .select('countries.name, countries.slug, COUNT(*) AS boats_count')
  end

  def show
    @country = Country.where(slug: params[:id]).first!
    @boats = @country.boats.not_deleted.boat_view_includes.page(params[:page]).per(20)
  end
end
