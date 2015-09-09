class BoatsForSaleController < ApplicationController
  def index
    @manufacturers = Manufacturer.joins(:boats).group('manufacturers.name, manufacturers.slug')
                         .order('COUNT(*) DESC').limit(20)
                         .select('manufacturers.name, manufacturers.slug, COUNT(*) AS boats_count')
  end

  def manufacturers_by_letter
    @letter = params[:letter]
    redirect_to(action: :index) if @letter.blank? || @letter !~ /\A[a-z]\z/

    @manufacturers = Manufacturer.where('name LIKE ?', "#{@letter}%").order(:name)
  end

  def manufacturer_boats
    @manufacturer = Manufacturer.where(slug: params[:manufacturer]).first!
    @boats = @manufacturer.boats.order(:name)
  end

  def show_boat
    @manufacturer = Manufacturer.where(slug: params[:manufacturer]).first!
    @boat = @manufacturer.boats.where(slug: params[:model]).first!
  end

  def boats_by_type_index
    @boat_types = BoatType.all
  end

  def boats_by_type
    @boat_type = BoatType.where(name: params[:boat_type]).first!
    @boats = @boat_type.boats.includes(:manufacturer)
  end

  def boats_by_location_index
    # @countries = Country.all
    @countries = Country.joins(:boats).group('countries.name, countries.slug')
                     .order('COUNT(*) DESC').limit(20)
                     .select('countries.name, countries.slug, COUNT(*) AS boats_count')
  end

  def boats_by_location
    @country = Country.where(slug: params[:country]).first!
    @boats = @country.boats.includes(:manufacturer)
  end
end