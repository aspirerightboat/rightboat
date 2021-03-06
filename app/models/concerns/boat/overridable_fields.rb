class Boat
  OVERRIDABLE_FIELDS = %w(name new_boat poa location geo_location year_built price length_m
         boat_type_id office_id manufacturer_id model_id country_id currency_id
         drive_type_id engine_manufacturer_id engine_model_id vat_rate_id
         fuel_type_id category_id offer_status length_f state)

  module OverridableFields
    extend ActiveSupport::Concern

    included do
      belongs_to :raw_boat, autosave: true, dependent: :destroy

      def import_assign(attr_name, value)
        if raw_boat
          if !field_overridden?(attr_name)
            send("#{attr_name}=", value)
          end
          raw_boat.send("#{attr_name}=", value)
        else
          send("#{attr_name}=", value)
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
        send(attr_name).presence != raw_boat.send(attr_name).presence
      end
    end

  end
end
