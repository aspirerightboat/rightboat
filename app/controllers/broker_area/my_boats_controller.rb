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
      @boat = current_broker.boats.new(boat_params)
      assign_makemodel

      if @boat.save
        assign_specs
        flash[:notice] = 'Boat created successfully.'
        redirect_to({action: :show, id: @boat.id})
      else
        flash.alert = @boat.errors.full_messages.join(', ')
        render :new
      end
    end

    def edit
      @boat = Boat.find_by(slug: params[:id])
      @specs_hash = @boat.boat_specifications.specs_hash
    end

    def show

    end

    def update
      @boat = Boat.find_by(slug: params[:id])
      assign_makemodel

      if @boat.save
        assign_specs
        flash[:notice] = 'Boat created successfully.'
        redirect_to({action: :show})
      else
        flash.alert = @boat.errors.full_messages.join(', ')
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
      t = BoatTemplate.find_or_try_create(params[:manufacturer_id], params[:model_id])
      if t
        render json: t.to_json
      else
        head :not_found
      end
    end

    private

    def boat_params
      params.require(:boat)
          .permit(:manufacturer_id, :model_id, :price, :year_built, :length_m, :description, :owners_comment,
                  :location, :tax_paid, :accept_toc, :agree_privacy_policy, :secure_payment, :currency_id, :boat_type_id,
                  boat_specifications_attributes: [:id, :value, :specification_id],
                  boat_images_attributes: [:id, :file, :file_cache, :_destroy]
          )
    end
  end

  def assign_makemodel
    @boat.manufacturer = if params[:manufacturer].to_s.start_with?('create:')
                           Manufacturer.find_or_create_by(name: params[:manufacturer].sub(/\Acreate:/, ''))
                         else
                           Manufacturer.find(params[:manufacturer])
                         end
    @boat.model = if params[:model].to_s.start_with?('create:')
                    Model.find_or_create_by(name: params[:model].sub(/\Acreate:/, ''), manufacturer: @boat.manufacturer)
                  else
                    Model.find(params[:model])
                  end
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
