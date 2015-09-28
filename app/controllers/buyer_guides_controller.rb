class BuyerGuidesController < ApplicationController

  before_filter :load_manufacturers

  def index
    @guides = BuyerGuide
    @guides = @guides.where(manufacturer_id: params[:manufacturer_id]) if params[:manufacturer_id].present?
    @guides = @guides.includes(:manufacturer, :model).
      order("manufacturers.name asc, models.name asc").published.limit(25)

    @page_title = "Boat Buyers Guides"
  end

  def show
    @guide = BuyerGuide.find(params[:id])
    @page_title = @guide.title
  end

  private

  def load_manufacturers
    @manufacturers = Manufacturer.joins(:buyer_guides).active
                       .where("buyer_guides.published = ?", true)
                       .group("manufacturers.id").having("count(buyer_guides.id) > 0")
  end
end
