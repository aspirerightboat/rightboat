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
      @boat = Boat.where(user: current_broker, manufacturer: manufacturer, model: model).first
      @boat ||= Boat.create(user: current_broker,
                            manufacturer: manufacturer,
                            model: model,
                            price: 0,
                            currency: Currency.default,
                            published: false,
                            expert_boat: true)
      @specs_hash = {}
    end

    def create
      @boat = current_broker.boats.new
      assign_boat_data

      if @boat.save
        assign_specs
        flash[:notice] = 'Boat created successfully.'
        redirect_to({action: :show, id: @boat})
      else
        flash.now.alert = @boat.errors.full_messages.join(', ')
        @specs_hash = params[:boat_specs]
        render :new
      end
    end

    def edit
      @boat = Boat.find_by(slug: params[:id])
      @specs_hash = @boat.boat_specifications.specs_hash
    end

    def show
      @boat = Boat.find_by(slug: params[:id])
      @boat_spec_by_name = @boat.boat_specifications.includes(:specification).index_by { |bs| bs.specification.name }
    end

    def update
      @boat = Boat.find_by(slug: params[:id])
      assign_boat_data

      if @boat.save
        assign_specs
        flash[:notice] = 'Boat created successfully.'
        redirect_to({action: :show})
      else
        flash.now.alert = @boat.errors.full_messages.join(', ')
        @specs_hash = params[:boat_specs]
        render :edit
      end
    end

    def destroy
      @boat.destroy
      redirect_to member_boats_path, notice: 'Boat deleted successfully.'
    end

    def upload_image
      @boat = Boat.find_by(slug: params[:id])
      bi = @boat.boat_images.new(file: params[:file])
      bi.save ? head(:ok) : head(:unprocessable_entity)
    end

    def find_template
      t = BoatTemplate.find_or_try_create(params[:manufacturer], params[:model])
      data = {}
      if t
        data.merge!(
            year_built: t.year_built,
            price: t.price.leave_significant(3),
            length_m: t.length_m,
            boat_type_id: t.boat_type_id,
            drive_type_id: t.drive_type_id,
            engine_manufacturer_id: t.engine_manufacturer_id,
            engine_model_id: t.engine_model_id,
            fuel_type_id: t.fuel_type_id,
            short_description: t.short_description,
            description: t.description,
            specs: t.specs,
        )
      end
      render json: data
    end

    private

    def boat_params
      params.require(:boat)
          .permit(:year_built, :length_m, :price, :boat_type_id, :poa # :description, :owners_comment, # :manufacturer_id, :model_id,
          # :location, :secure_payment, :boat_type_id,
          #         boat_specifications_attributes: [:id, :value, :specification_id],
          #         boat_images_attributes: [:id, :file, :file_cache, :_destroy]
          )
    end

    def assign_boat_data
      @boat.manufacturer = if params[:manufacturer]
                             Manufacturer.create_with(created_by_user: current_broker)
                                 .find_or_create_by(name: params[:manufacturer])

                           end
      @boat.model = if params[:model] && @boat.manufacturer
                      Model.create_with(created_by_user: current_broker)
                          .find_or_create_by(name: params[:model], manufacturer: @boat.manufacturer)

                    end
      @boat.assign_attributes(boat_params)
      @boat.currency = Currency.cached_by_name(params[:price_currency])
      @boat.vat_rate = params[:vat_included].present? ? VatRate.tax_paid : VatRate.tax_unpaid
    end

    def assign_specs
      boat_specs = @boat.boat_specifications.includes(:specification)
      params[:boat_specs].each do |spec_name, spec_value|
        boat_spec = boat_specs.find { |bs| bs.specification.name == spec_name } ||
            @boat.boat_specifications.new(specification: Specification.find_by(name: spec_name))
        boat_spec.value = spec_value
        boat_spec.save!
      end
      params_spec_names = params[:boat_specs].map(&:first)
      @boat.boat_specifications.select { |bs| !bs.specification.name.in?(params_spec_names) }.each do
        bs.destroy!
      end
    end

  end
end
