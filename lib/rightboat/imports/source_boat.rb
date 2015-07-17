require 'nokogiri'

module Rightboat
  module Imports
    class SourceBoat
      include ActiveModel::Validations
      include Utils

      validates_presence_of :user, :source_id, :manufacturer, :model
      validate :require_price, :require_location

      NORMAL_ATTRIBUTES = [
        :source_id, :name, :description, :poa, :price, :year_built, :under_offer, :length_m, :new_boat, :source_url, :owners_comment
      ]

      SPEC_ATTRS = [
        :hull_type, :hull_shape, :hull_material, :hull_color, :cockpit_type,
        :flybridge, :air_conditioning, :stern_thruster, :bow_thruster,
        :range, :lwl_m, :draft_m,
        :engine_count, :engine_type, :engine_location, :beam_m, :engine_horse_power, :engine_hours, :max_speed, :cruising_speed,
        :displacement_kgs, :ballast, :electrical_circuit,
        :heads, :berths, :single_berths, :double_berths, :cabins, :keel, :fresh_water_tanks, :holding_tanks,
        :fuel_tanks, :designer, :head_room, :builder, :length_on_deck, :propeller, :dry_weight, :passengers,
        :gps, :vhf, :plotter, :radar, :battery_charger, :generator, :inverter, :bimini,
        :television, :cd_player, :dvd_player, :cylinders, :gearbox,
        :known_defects, :last_serviced, :air_draft, :hull_construction, :hull_number,
        :super_structure_colour, :super_structure_construction, :deck_colour, :deck_construction, :spray_hood,
        :control_type, :keel_type, :oven, :microwave, :fridge, :freezer, :heating, :tankage, :gallons_per_hour,
        :litres_per_hour, :propeller_type, :starting_type, :cooling_system, :navigation_lights, :compass,
        :depth_instrument, :wind_instrument, :autopilot, :speed_instrument, :toilet, :shower, :bath, :life_raft,
        :epirb, :bilge_pump, :fire_extinguisher, :mob_system, :genoa, :spinnaker, :tri_sail, :storm_jib,
        :main_sail, :winches, :battery, :shorepower, :fenders, :anchor
      ]

      RELATION_ATTRIBUTES = [
        :engine_model, :drive_type, :currency, :manufacturer, :model, :fuel_type, :vat_rate, :engine_manufacturer, :engine_model, :boat_type
      ]

      DYNAMIC_ATTRIBUTES = [
        :import, :user, :images, :tax_status, :update_country, :country, :location, :office
      ]

      attr_accessor :missing_spec_attrs
      attr_accessor *DYNAMIC_ATTRIBUTES
      attr_accessor *SPEC_ATTRS
      attr_accessor *NORMAL_ATTRIBUTES
      attr_accessor *RELATION_ATTRIBUTES

      (NORMAL_ATTRIBUTES + SPEC_ATTRS + DYNAMIC_ATTRIBUTES + RELATION_ATTRIBUTES).each do |attr_name|
        define_method "#{attr_name}=" do |v|
          instance_variable_set "@#{attr_name}".to_sym, cleanup_string(v)
        end
      end

      def save
        unless valid?
          Rails.logger.error "Scraper seems wrong: Import(#{self.import.id}/#{self.source_id}) - #{self.errors.full_messages.join("\n")}"
          return
          # TODO: mailing system for unexpected fail
        end

        user_id = user.respond_to?(:id) ? user.id : user

        target = Boat.unscoped.where(user_id: user_id, source_id: source_id).first_or_initialize
        target.import = self.import
        adjust_location(target)

        NORMAL_ATTRIBUTES.each do |attr_name|
          value = instance_variable_get("@#{attr_name}".to_sym)
          value = nil if value.blank? || value.to_s =~ /^[\.0]+$/
          target.send "#{attr_name}=", value
        end
        target.revive if target.deleted?

        spec_proc = Proc.new do |attr_name, value|
          value ||= instance_variable_get("@#{attr_name}".to_sym)
          value = nil if value.blank? || value.to_s =~ /^[\.0]+$/
          value = nil if value =~ /^false$/i
          value = 'Yes' if value =~ /^true$/i

          is_blank_value = value.blank? || value.to_s =~ /^[\.0]+$/

          spec = Specification.query_with_aliases(attr_name).first_or_initialize
          if spec.new_record?
            spec.display_name = attr_name.to_s.titleize
            spec.save! unless is_blank_value
          end

          if target.new_record?
            spec_attrs = {specification_id: spec.id, value: value}
            target.boat_specifications.build(spec_attrs) unless is_blank_value
          else
            boat_spec = target.boat_specifications.where(specification_id: spec.id).first_or_initialize
            if is_blank_value
              boat_spec.destroy unless boat_spec.new_record?
            else
              boat_spec.value = value
              boat_spec.save!
            end
          end
        end

        SPEC_ATTRS.each { |attr_name| spec_proc.call(attr_name) }
        @missing_spec_attrs.each { |attr_name, v| spec_proc.call(attr_name, v) }

        RELATION_ATTRIBUTES.each do |attr_name|
          klass = attr_name.to_s.camelize.constantize
          value = instance_variable_get("@#{attr_name}".to_sym)
          if attr_name.to_sym == :model
            query_option = { manufacturer_id: target.manufacturer_id }
          elsif attr_name.to_sym == :engine_model
            query_option = { engine_manufacturer_id: target.engine_manufacturer_id }
          else
            query_option = {}
          end
          if value.blank? || value.to_s =~ /^[\.0]+$/
            relation_record = nil
          elsif attr_name.to_sym == :currency
            relation_record = klass.find_by_name(value)
            # TODO: report error for nil currency
          else
            relation_record = klass.query_with_aliases(value).where(query_option).first_or_create
          end
          target.send "#{attr_name}=", relation_record
        end

        unless @office.blank?
          office_attrs = @office.symbolize_keys
          office = Office.where(user_id: @user.id, name: office_attrs[:name]).first_or_initialize
          office.update_attributes!(@office)
          target.office = office
        end

        images.each do |url|
          if target.new_record?
            img = BoatImage.new(source_url: url, boat: target)
            img.cache_file_from_source_url
            target.boat_images << img if img.valid?
          else
            img = target.boat_images.where(source_url: url).first_or_initialize
            img.cache_file_from_source_url
            img.save
          end
        end

        if target.boat_images.blank?
          target.destroy
        else
          unless target.save
            puts "**** ERROR: \n#{target.errors.full_messages.join("\n")}\n****"
          end
        end

      end

      # boat spec that is not managed
      def set_missing_attr(attr, value)
        @missing_spec_attrs ||= {}
        @missing_spec_attrs[attr] = value
      end

      private
      def require_price
        if !poa && price.blank?
          self.errors.add :price, "can't be blank"
        end
      end

      def require_location
        if location.blank? && country.blank?
          self.errors.add :location, "can't be blank"
        end
      end

      def adjust_location(target)
        if country.to_s.downcase == location.to_s.downcase
          self.location = ''
        end

        if country.to_s.downcase == "uk"
          self.country = "GB"
        end
        full_location = [location.to_s, country.to_s].reject(&:blank?).join(', ')
        if full_location.downcase != target.geo_location
          if !country.blank?
            _country = Country.joins(:misspellings).where("misspellings.alias_string = :name OR name = :name OR iso = :name", name: country).first
          end
          if _country
            target.country = _country
            target.geo_location = full_location.downcase
          else
            # Geocoder.configure(
            #   http_proxy: 'http://uk.proxymesh.com:31280',
            #   timeout: 15
            # )

            geo_result = Geocoder.search(full_location, lookup: :google).first
            if geo_result
              self.country = geo_result.country_code
              rcc = "#{Regexp.escape(geo_result.country_code)}|#{Regexp.escape(geo_result.country)}"
              self.location = full_location.strip.gsub(/([\s,]+)?(#{rcc})([^\w])?$/i, '')
              target.geo_location = full_location.downcase
              self.update_country = true
            end
          end

          if update_country
            target.country = Country.find_by_iso(country) unless country.blank?
            unless target.country || !country.blank?
              target.country = Country.where("name LIKE ?", "#{country}%").first
            end
          end

          target.location = location
          if target.country
            rcc = ("#{Regexp.escape(target.country.iso)}|#{Regexp.escape(target.country.name)}")
            target.location = location.to_s.gsub(/([\s,]+)?(#{rcc})?([^\w])?$/i, '')
          else
            target.location.gsub!(/[\s,]+$/, '')
          end
        end
      end

    end
  end
end