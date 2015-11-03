class Api::ManufacturersController < ApplicationController
  def models
    render json: Model.where(manufacturer_id: params[:id]).order(:name).pluck(:id, :name), root: false
  end
end