class CountriesController < ApplicationController
  def show
    @country = Country.find_by(slug: params[:id])
    redirect_to root_path and return if !@country

    fixed_params = {
      country_id: @country.id,
      page: params[:page],
      order: params[:order]
    }
    @boats = Rightboat::BoatSearch.new.do_search(params: fixed_params).results
  end
end
