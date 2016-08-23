module BoatOverridableFields
  extend ActiveSupport::Concern

  OVERRIDABLE_FIELDS = %w(name new_boat poa location geo_location year_built price length_m
       boat_type_id office_id manufacturer_id model_id country_id currency_id
       drive_type_id engine_manufacturer_id engine_model_id vat_rate_id
       fuel_type_id category_id offer_status length_f state)

  included do
    belongs_to :raw_boat, autosave: true, dependent: :destroy

    OVERRIDABLE_FIELDS.each do |attr_name|
      define_method "#{attr_name}=" do |value|
        assign_overridable_field(attr_name, value)
      end
      if attr_name.end_with?('_id')
        association = attr_name.chomp('_id')
        define_method "#{association}=" do |value|
          assign_overridable_field(association, value)
        end
      end
    end

    def assign_overridable_field(attr_name, value)
      if Import.import_running?
        assign_imported_value(attr_name, value)
      else
        override_imported_value(attr_name, value)
      end
    end

    def assign_imported_value(attr_name, value)
      if raw_boat
        if send(attr_name).presence == raw_boat.send(attr_name).presence
          self[attr_name] = value
        end
        raw_boat.send("#{attr_name}=", value)
      else
        self[attr_name] = value
      end
    end

    def override_imported_value(attr_name, value)
      if import_id && !expert_boat? && !raw_boat
        build_raw_boat(attributes.slice(*OVERRIDABLE_FIELDS))
      end
      self[attr_name] = value
    end

    def imported_field_value(attr_name)
      raw_boat ? raw_boat.send(attr_name) : send(attr_name)
    end

    def field_overridden?(attr_name)
      raw_boat && send(attr_name).presence != raw_boat.send(attr_name).presence
    end
  end

end
