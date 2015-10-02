class Api::ManufacturersController < ApplicationController
  def models
    render json: Model.where(manufacturer_id: params[:id]).pluck(:id, :name), root: false
  end
end