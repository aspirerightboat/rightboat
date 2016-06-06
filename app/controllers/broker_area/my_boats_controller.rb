module BrokerArea
  class MyBoatsController < CommonController

    def index
      @boats = current_broker.boats.active.boat_view_includes.includes(:country).page(params[:page]).per(15)
      @boats = @boats.where(office_id: params[:office_id]) if params[:office_id].present?
      @offices = current_broker.offices.order(:name)
    end

    def new
      manufacturer = Manufacturer.find_or_create_by(name: 'Unknown')
      model = Model.find_or_create_by(name: 'Unknown', manufacturer: manufacturer)

      @boat = Boat.create(user: current_broker, manufacturer: manufacturer, model: model, price: 123, currency: Currency.default)
      @specs_hash = @boat.boat_specifications.specs_hash
    end

    # EDITABLE_SPEC_NAMES = %w(beam_m draft_m air_draft_m lwl_m fresh_water_tanks displacement_kgs
    #                          engine_type engine_horse_power engine_count hull_type number_on_cabins number_on_berths)
    #
    # def build_specifications
    #   @boat_specs = @boat.boat_specifications.includes(:specification).to_a
    #
    #   build_specs = Specification.where(name: EDITABLE_SPEC_NAMES).to_a
    #   build_specs.delete_if { |s| @boat_specs.any? { |bs| bs.specification_id == s.id } }
    #   build_specs.each do |s|
    #     @boat_specs << BoatSpecification.new(boat: @boat, specification: s)
    #   end
    #
    #   @boat_spec_by_name = @boat_specs.index_by { |bs| bs.specification.name }
    # end

    # def create
    #   @boat = current_broker.boats.new(boat_params)
    #
    #   if @boat.save
    #     flash[:notice] = 'Boat created successfully.'
    #     if params[:boat][:sell_request_type].present?
    #       params[:boat][:sell_request_type].each do |sell_request_type|
    #         UserMailer.new_sell_request(@boat.id, sell_request_type).deliver_now unless params[:boat][:sell_request_type].blank?
    #       end
    #     end
    #     render json: { location: member_boats_path }
    #   else
    #     render json: @boat.errors.full_messages, root: false, status: 422
    #   end
    # end

    def edit
      @boat = Boat.includes(boat_specifications: :specification).find_by(slug: params[:id])
      build_specifications
    end

    # def update
    #   if @boat.update(boat_params)
    #     flash[:notice] = 'Boat updated successfully.'
    #     render json: { location: member_boats_path }
    #   else
    #     render json: @boat.errors.full_messages, root: false, status: 422
    #   end
    # end
    #
    # def destroy
    #   @boat.destroy
    #   redirect_to member_boats_path, notice: 'Boat deleted successfully.'
    # end

    def upload_image
      @boat = Boat.find_by(slug: params[:id])
      bi = @boat.boat_images.new(file: params[:file])
      bi.save ? head(:ok) : head(:unprocessable_entity)
    end

    # private
    #
    # def boat_params
    #   params.require(:boat)
    #       .permit(:manufacturer_id, :model_id, :price, :year_built, :length_m, :description, :owners_comment,
    #               :location, :tax_paid, :accept_toc, :agree_privacy_policy, :secure_payment, :currency_id,
    #               boat_specifications_attributes: [:id, :value, :specification_id],
    #               boat_images_attributes: [:id, :file, :file_cache, :_destroy]
    #       )
    # end
  end
end
