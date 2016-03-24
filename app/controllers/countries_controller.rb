class CountriesController < ApplicationController
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
