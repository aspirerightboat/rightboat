module BrokerArea
  class MyBoatsController < CommonController
    protect_from_forgery except: :upload_image
    include Rightboat::BoatDescriptionUtils
    before_filter :load_boat, only: [:edit, :show, :update, :destroy, :upload_image, :remove_image, :move_image, :toggle_published]

    def index
      @boats = current_broker.boats.not_deleted.boat_view_includes.includes(:country, :office).page(params[:page]).per(30)
      @boats = @boats.where(id: Boat.id_from_ref_no(params[:ref_no])) if params[:ref_no].present?
      @boats = @boats.where(source_id: params[:source_id]) if params[:source_id].present?
      @boats = @boats.where(office_id: params[:office_id]) if params[:office_id].present?
      @boats = @boats.joins(:manufacturer).where('manufacturers.name LIKE ?', "%#{params[:manufacturer_q]}%") if params[:manufacturer_q].present?
      @boats = @boats.joins(:model).where('models.name LIKE ?', "%#{params[:model_q]}%") if params[:model_q].present?
      @boats = @boats.where(offer_status: params[:offer_status]) if params[:offer_status].present?
      @boats = @boats.where(published: case params[:published] when '1' then true when '0' then false end) if params[:published].present?
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

    def edit
      @boat.price = @boat.price.to_i if @boat.price == @boat.price.to_i
      @specs_hash = @boat.boat_specifications.specs_hash
    end

    def show
      @boat_spec_by_name = @boat.boat_specifications.includes(:specification).index_by { |bs| bs.specification.name }
    end

    def update
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
      redirect_to broker_area_my_boats_path, notice: 'Boat deleted successfully.'
    end

    def upload_image
      bi = @boat.boat_images.new(file: params[:file])
      bi.position = (@boat.boat_images.maximum(:position) || 0) + 10

      if bi.save
        render json: {id: bi.id}
      else
        head :unprocessable_entity
      end
    end

    def remove_image
      bi = @boat.boat_images.find(params[:image])

      if bi.destroy
        head :ok
      else
        head :bad_request
      end
    end

    def move_image
      bi = @boat.boat_images.find(params[:image])
      bi_prev = (@boat.boat_images.find(params[:prev]) if params[:prev].present?)
      bi_next = (@boat.boat_images.find(params[:next]) if params[:next].present?)

      prev_pos = bi_prev&.position || 0
      next_pos = bi_next&.position || 0
      bi.position = (prev_pos + next_pos) / 2
      bi.position = prev_pos + 1 if bi.position <= prev_pos
      bi.update_column(:position, bi.position)

      if bi.position >= next_pos
        if next_pos > prev_pos
          @boat.boat_images.where('position >= ?', next_pos).where('id <> ?', bi.id).update_all('position = position + 10')
        else
          image_ids = @boat.boat_images.pluck(:id).drop_while { |bi_id| bi_id != bi_next&.id }.select { |bi_id| bi_id != bi.id }
          BoatImage.where(id: image_ids).update_all('position = position + 10') if image_ids.any?
        end
      end

      head :ok
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
            drive_type: t.drive_type&.name,
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

    def toggle_published
      if @boat.update published: params[:published]
        head :ok
      else
        head :unprocessable_entity
      end
    end

    private

    def boat_params
      params.require(:boat).permit(
          :name, :year_built, :length_m, :price, :boat_type_id, :poa, :location,
          :source_id, :offer_status, :published, extra_attributes: [:id, :short_description, :description, :owners_comment, :disclaimer]
      )
    end

    def assign_boat_data
      @boat.manufacturer = if params[:manufacturer].present?
                             Manufacturer.create_with(created_by_user: current_broker)
                                 .where(name: params[:manufacturer]).first_or_create

                           end
      @boat.model = if params[:model].present? && @boat.manufacturer
                      Model.create_with(created_by_user: current_broker)
                          .where(name: params[:model], manufacturer: @boat.manufacturer).first_or_create

                    end
      @boat.assign_attributes(boat_params)
      @boat.extra.description = cleanup_description(@boat.extra.description) if @boat.extra.description.present?
      @boat.extra.short_description = cleanup_short_description(@boat.extra.short_description) if @boat.extra.short_description.present?
      @boat.currency = Currency.cached_by_name(params[:price_currency])
      @boat.vat_rate = params[:vat_included].present? ? VatRate.tax_paid : VatRate.tax_unpaid
      @boat.fuel_type = if params[:fuel_type].present?
                          FuelType.create_with(created_by_user: current_broker)
                              .where(name: params[:fuel_type]).first_or_create
                        end
      @boat.engine_manufacturer = if params[:engine_manufacturer].present?
                                    EngineManufacturer.create_with(created_by_user: current_broker)
                                        .where(name: params[:engine_manufacturer]).first_or_create
                                  end
      @boat.engine_model = if params[:engine_model].present? && @boat.engine_manufacturer
                             EngineModel.create_with(created_by_user: current_broker)
                                 .where(name: params[:engine_model], engine_manufacturer: @boat.engine_manufacturer).first_or_create
                           end
      @boat.country = if params[:country].present?
                        Country.find_by(name: params[:country])
                      end
      @boat.drive_type = if params[:drive_type].present?
                             DriveType.create_with(created_by_user: current_broker)
                                 .where(name: params[:drive_type]).first_or_create
                         end
      @boat.office = if params[:office].present?
                       Office.find_by(id: params[:office])
                     end
      @boat.new_boat = case params[:newness] when 'new' then true when 'used' then false end
    end

    def assign_specs
      boat_specs = @boat.boat_specifications.includes(:specification)
      params_boat_specs = params[:boat_specs].select { |_k, v| v.present? }
      params_boat_specs.each do |spec_name, spec_value|
        boat_spec = boat_specs.find { |bs| bs.specification.name == spec_name }
        if !boat_spec && (spec = Specification.find_by(name: spec_name))
          boat_spec = @boat.boat_specifications.new(specification: spec)
        end
        if boat_spec
          boat_spec.value = spec_value
          boat_spec.save! if boat_spec.changed?
        end
      end
      params_spec_names = params_boat_specs.map(&:first)
      boat_specs.each do |bs|
        bs.destroy! if !bs.specification.name.in?(params_spec_names)
      end
    end

    def load_boat
      @boat = Boat.find_by(slug: params[:id])
    end

  end
end
