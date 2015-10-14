class Member::BoatsController < Member::BaseController

  before_filter :load_boat, only: [:edit, :update, :destroy]

  def index
    @my_boats = current_user.boats.includes(:currency, :manufacturer, :model, :country, :primary_image, :vat_rate)
  end

  def new
    @boat = Boat.new
    build_specifications
  end

  def create
    @boat = current_user.boats.new(boat_params)

    if @boat.save
      redirect_to member_boats_path, notice: 'Boat created successfully.'
    else
      render :new
    end
  end

  def edit
    build_specifications
  end

  def update
    if @boat.update(boat_params)
      redirect_to member_boats_path, notice: 'Boat updated successfully.'
    else
      render :edit
    end
  end

  def destroy
    @boat.destroy(:force)
    redirect_to member_boats_path, notice: 'Boat deleted successfully.'
  end

  private

  def load_boat
    @boat = Boat.find(params[:id])
  end

  def build_specifications
    ['beam_m', 'draft_m', 'engine_type', 'engine_horse_power', 'engine_count', 'hull_type', 'number_on_cabins', 'number_on_berths'].each do |x|
      spec = Specification.where('LOWER(name) LIKE ?', "%#{x}%").first
      @boat.boat_specifications.build(specification: spec) if @boat.boat_specifications.where(specification: spec).empty?
    end
    @boat.boat_images.build if @boat.boat_images.empty?
  end

  def boat_params
    params.require(:boat)
      .permit(:manufacturer_id, :model_id, :price, :year_built, :length_m, :description, :owners_comment,
              :location, :tax_paid, :accept_toc, :agree_privacy_policy, :secure_payment,
              boat_specifications_attributes: [:id, :value, :specification_id],
              boat_images_attributes: [:id, :file, :file_cache, :_destroy]
      )
  end
end