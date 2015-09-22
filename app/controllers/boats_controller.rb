class BoatsController < ApplicationController
  before_filter :set_back_link, only: [:show]
  after_filter :store_recent, only: [:show]

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
    @manufacturer = Manufacturer.where(slug: params[:slug]).first!
    @boats = @manufacturer.boats.includes(:currency, :model, :primary_image, :vat_rate, :country).order(:name)
  end

  def show_boat
    @boat = Boat.where(slug: params[:slug]).first!
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


  def show
    @boat = Boat.find(params[:id])
  end

  def pdf
    @boat = Boat.find(params[:boat_id])
    render pdf: 'pdf', layout: 'pdf'
  end

  private

  def set_back_link
    if request.referer =~ /^([^\?]+)?\/search(\?.*)?$/
      @back_url = request.referer.to_s
    end
  end

  def store_recent
    attrs = { target_id: @boat.id, action: :show, ip: request.remote_ip }

    if (activity = Activity.where(attrs).first)
      activity.inc(count: 1)
    else
      Activity.create(attrs.merge(user_id: current_user.try(:id)))
    end
  end
end