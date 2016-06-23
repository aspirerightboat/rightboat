module BrokerArea
  class MyBoatsController < CommonController
    protect_from_forgery except: :upload_image

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
        flash[:notice] = 'Boat updated successfully.'
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
            engine_manufacturer: t.engine_manufacturer&.name,
            engine_model: t.engine_model&.name,
            fuel_type: t.fuel_type&.name,
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
          .permit(:year_built, :length_m, :price, :boat_type_id, :poa, :location, :description #, :owners_comment, # :manufacturer_id, :model_id,
          # :location, :secure_payment,
          #         boat_specifications_attributes: [:id, :value, :specification_id],
          #         boat_images_attributes: [:id, :file, :file_cache, :_destroy]
          )
    end

    def assign_boat_data
      @boat.manufacturer = if params[:manufacturer]
                             Manufacturer.create_with(created_by_user: current_broker)
                                 .where(name: params[:manufacturer]).first_or_create

                           end
      @boat.model = if params[:model] && @boat.manufacturer
                      Model.create_with(created_by_user: current_broker)
                          .where(name: params[:model], manufacturer: @boat.manufacturer).first_or_create

                    end
      @boat.assign_attributes(boat_params)
      @boat.currency = Currency.cached_by_name(params[:price_currency])
      @boat.vat_rate = params[:vat_included].present? ? VatRate.tax_paid : VatRate.tax_unpaid
      @boat.fuel_type = if params[:fuel_type]
                          FuelType.create_with(created_by_user: current_broker)
                              .where(name: params[:fuel_type]).first_or_create
                        end
      @boat.engine_manufacturer = if params[:engine_make]
                                    EngineManufacturer.create_with(created_by_user: current_broker)
                                        .where(name: params[:engine_make]).first_or_create
                                  end
      @boat.engine_model = if params[:engine_model] && @boat.engine_manufacturer
                             EngineModel.create_with(created_by_user: current_broker)
                                 .where(name: params[:engine_model], engine_manufacturer: @boat.engine_manufacturer).first_or_create
                           end
      @boat.country = if params[:country]
                        Country.find_by(name: params[:country])
                      end
      @boat.drive_type = if params[:drive_type]
                             DriveType.create_with(created_by_user: current_broker)
                                 .where(name: params[:drive_type]).first_or_create
                           end
    end

    def assign_specs
      boat_specs = @boat.boat_specifications.includes(:specification)
      params_boat_specs = params[:boat_specs].select { |_k, v| v.present? }
      params_boat_specs.each do |spec_name, spec_value|
        boat_spec = boat_specs.find { |bs| bs.specification.name == spec_name } ||
            @boat.boat_specifications.new(specification: Specification.find_by(name: spec_name))
        boat_spec.value = spec_value
        boat_spec.save!
      end
      params_spec_names = params_boat_specs.map(&:first)
      boat_specs.select { |bs| !bs.specification.name.in?(params_spec_names) }.each do
        bs.destroy!
      end
    end

  end
end
