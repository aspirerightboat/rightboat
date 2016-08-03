class Member::BoatsController < Member::BaseController

  before_filter :ensure_non_broker
  before_filter :load_boat, only: [:edit, :update, :destroy]

  def index
    @my_boats = current_user.boats.not_deleted.includes(:currency, :manufacturer, :model, :country, :primary_image, :vat_rate)
  end

  def new
    @boat = Boat.new
    build_specifications
  end

  def create
    @boat = current_user.boats.new(boat_params.merge(published: false))

    if @boat.save
      flash[:notice] = 'Boat created successfully.'
      if params[:boat][:sell_request_type].present?
        params[:boat][:sell_request_type].each do |sell_request_type|
          StaffMailer.new_sell_request(@boat.id, sell_request_type).deliver_now unless sell_request_type.blank?
        end
      end
      render json: { location: member_boats_path }
    else
      render json: @boat.errors.full_messages, root: false, status: 422
    end
  end

  def edit
    build_specifications
  end

  def update
    if @boat.update(boat_params)
      flash[:notice] = 'Boat updated successfully.'
      render json: { location: member_boats_path }
    else
      render json: @boat.errors.full_messages, root: false, status: 422
    end
  end

  def destroy
    @boat.destroy
    redirect_to member_boats_path, notice: 'Boat deleted successfully.'
  end

  private

  def ensure_non_broker
    redirect_to member_root_path if current_user.company?
  end

  def load_boat
    @boat = current_user.boats.find(Boat.id_from_ref_no(params[:id]))
  end

  def build_specifications
    %w(beam_m draft_m engine_type engine_horse_power engine_count hull_type number_on_cabins number_on_berths).each do |x|
      spec = Specification.where(name: x).first
      @boat.boat_specifications.build(specification: spec) if @boat.boat_specifications.where(specification: spec).empty?
    end
    # @boat.boat_images.build if @boat.boat_images.empty?
  end

  def boat_params
    params.require(:boat)
      .permit(:manufacturer_id, :model_id, :price, :year_built, :length_m, :custom_model,
              :location, :tax_paid, :accept_toc, :agree_privacy_policy, :secure_payment, :currency_id,
              boat_specifications_attributes: [:id, :value, :specification_id],
              boat_images_attributes: [:id, :file, :file_cache, :_destroy],
              extra_attributes: [:id, :description, :owners_comment]
      )
  end
end
