class Api::ManufacturersController < ApplicationController
  before_filter :load_manufacturer

  def models
    search = Sunspot.search(Model) do |q|
      q.with :manufacturer_id, @manufacturer.id
      q.paginate per_page: 1000
    end
    json = search.results.map { |model| [model.id, model.name] }

    render json: json, root: false
  end

  private
  def load_manufacturer
    @manufacturer = Manufacturer.find(params[:id])
  end
end