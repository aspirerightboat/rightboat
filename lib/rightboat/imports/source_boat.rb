require 'nokogiri'

module Rightboat
  module Imports
    class SourceBoat
      class_attribute :mnm_fixes

      include ActiveModel::Validations
      include Utils

      validates_presence_of :user, :source_id, :manufacturer, :model

      NORMAL_ATTRIBUTES = [
        :source_id, :name, :description, :poa, :price, :year_built, :under_offer, :length_m, :new_boat, :source_url, :owners_comment
      ]

      SPEC_ATTRS = [
        :hull_type, :hull_shape, :hull_material, :hull_color, :cockpit_type,
        :flybridge, :air_conditioning, :stern_thruster, :bow_thruster, :bridge, :rig,
        :range, :lwl_m, :draft_m,
        :engine_count, :engine_type, :engine_location, :engine_horse_power, :engine_hours, :engine, :engine_code, :engine_year,
        :displacement_kgs, :ballast, :electrical_circuit, :max_speed, :cruising_speed, :beam_m,
        :heads, :berths, :single_berths, :double_berths, :twin_berths, :cabins, :keel, :fresh_water_tanks, :holding_tanks,
        :fuel_tanks, :designer, :head_room, :builder, :length_on_deck, :propeller, :dry_weight, :passengers, :bathrooms,
        :gps, :vhf, :plotter, :radar, :battery_charger, :generator, :inverter, :bimini,
        :television, :cd_player, :dvd_player, :cylinders, :gearbox,
        :known_defects, :last_serviced, :air_draft, :hull_construction, :hull_number,
        :super_structure_colour, :super_structure_construction, :deck_colour, :deck_construction, :spray_hood,
        :control_type, :keel_type, :oven, :microwave, :fridge, :freezer, :heating, :tankage, :gallons_per_hour,
        :litres_per_hour, :propeller_type, :starting_type, :cooling_system, :navigation_lights, :compass,
        :depth_instrument, :wind_instrument, :autopilot, :speed_instrument, :toilet, :shower, :bath, :life_raft,
        :epirb, :bilge_pump, :fire_extinguisher, :mob_system, :genoa, :spinnaker, :tri_sail, :storm_jib,
        :main_sail, :winches, :battery, :shorepower, :fenders, :anchor, :seating_capacity, :drive_transmission_description,
      ]

      RELATION_ATTRIBUTES = [
        :drive_type, :currency, :manufacturer, :model, :fuel_type, :vat_rate, :engine_manufacturer, :engine_model, :boat_type, :category
      ]

      DYNAMIC_ATTRIBUTES = [
        :import, :error_msg, :user, :images, :images_count, :new_record, :tax_status, :update_country, :country, :location,
        :office, :office_id, :target, :import_base
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

      def manufacturer_model=(mnm)
        # some sources has only merged string instead of separate manufacturer/model
        # in this case, search db and find first
        # if not exists in db, use split method
        #  e.g. yachtworld: Marine Projects Sigma 38, Alloy Yachts Pilothouse

        search = Sunspot.search(Boat) do |q|
          q.with :manufacturer_model, mnm
          q.order_by :live, :desc
          q.paginate per_page: 1
        end
        if (boat = search.results.first)
          self.manufacturer = boat.manufacturer
          self.model = boat.model
        else
          tokens = mnm.split(/\s+/).reject(&:blank?)
          manufacturer = tokens[0..-2].join(' ')
          model = tokens[-1]
          ((1 - tokens.count)..0).each do |i|
            manufacturer = tokens[0..i].join(' ')
            model = tokens[(i + 1)..-1].join(' ')
            search = Sunspot.search(Manufacturer) do |q|
              q.with :name, manufacturer
              q.paginate per_page: 1
            end
            break if search.raw_results.first
          end

          self.manufacturer, self.model = manufacturer, model
        end
      end

      def initialize(attrs = {})
        attrs.each do |k, v|
          send "#{k}=", v
        end
      end

      def save
        if !valid?
          self.error_msg = "SAVE BOAT ERROR1: #{errors.full_messages.join(', ')}"
          return false
        end

        user_id = user.respond_to?(:id) ? user.id : user
        self.target = Boat.where(user_id: user_id, source_id: source_id).first_or_initialize
        target.import = import

        adjust_location(target)

        NORMAL_ATTRIBUTES.each do |attr_name|
          value = instance_variable_get("@#{attr_name}".to_sym)
          value = nil if value.blank? || value.to_s =~ /^[\.0]+$/
          if attr_name == :description && value
            remove_contact_info!(value)
          end
          target.send "#{attr_name}=", value
        end
        # target.revive(true) if target.deleted?

        spec_proc = Proc.new do |attr_name, value|
          value ||= instance_variable_get("@#{attr_name}".to_sym)
          value = nil if value.blank? || value.to_s =~ /^[\.0]+$/ || value =~ /^false$/i
          value = 'Yes' if value =~ /^(true|1|yes)$/i

          is_blank_value = value.blank? || value.to_s =~ /^[\.0]+$/

          spec = Specification.where(name: attr_name).first_or_initialize
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
              boat_spec.destroy if boat_spec.persisted?
            else
              boat_spec.value = value
              boat_spec.save!
            end
          end
        end

        SPEC_ATTRS.each { |attr_name| spec_proc.call(attr_name) }
        if @missing_spec_attrs.present?
          @missing_spec_attrs.each { |attr_name, v| spec_proc.call(attr_name, v) }
        end

        RELATION_ATTRIBUTES.each do |attr_name|
          klass = Boat.reflections[attr_name.to_s].klass
          value = instance_variable_get("@#{attr_name}".to_sym)
          unless value.is_a?(ActiveRecord::Base)
            if value.blank? || value.to_s =~ /^[\.0]+$/
              value = nil
            elsif attr_name == :currency
              value = 'USD' if value == '$' # there are other currencies with $ symbol: AUD, CAD, HKD, NZD, SGD but USD is by default
              value = Currency.where('name = ? OR symbol = ?', value, value).first
              if value.nil?
                self.error_msg = "Currency Not Found: #{value}"
                ImportMailer.blank_currency(self).deliver_now
              end
            else
              if attr_name == :model
                query_option = { manufacturer_id: target.manufacturer_id }
              elsif attr_name == :engine_model
                query_option = { engine_manufacturer_id: target.engine_manufacturer_id }
              else
                query_option = {}
              end
              value = klass.query_with_aliases(value).where(query_option).create_with(query_option).first_or_create!
            end
          end

          target.send "#{attr_name}=", value
        end

        if office.present?
          import_base.jobs_mutex.synchronize do
            @@user_offices ||= user.offices.includes(:address).to_a

            office_attrs = office.symbolize_keys
            office = @@user_offices.find { |o| o.name == office_attrs[:name] } || user.offices.new(name: office_attrs[:name])
            office.name = user.company_name if office_attrs[:name].blank? && @@user_offices.none?
            office.address ||= Address.new
            office.assign_attributes(office_attrs)

            @@user_offices << office if office.new_record?
            office.save! if office.changed?
            office.address.save! if office.address.changed?
            target.office = office
          end
        end
        target.office_id = office_id if office_id

        target.poa = price.blank? || price.to_i <= 0

        self.images_count = 0
        boat_images_by_url = (target.boat_images.index_by(&:source_url) if target.persisted?)

        images.each do |url|
          url.strip!
          img = (boat_images_by_url[url] if target.persisted?) || BoatImage.new(source_url: url, boat: target)
          img.cache_file_from_source_url
          if target.new_record?
            if img.valid?
              target.boat_images << img
              self.images_count += 1
            end
          else
            success = img.save
            self.images_count += 1 if success
          end
        end

        self.new_record = target.new_record?
        success = target.save
        if !success
          self.error_msg = "SAVE BOAT ERROR2: #{target.errors.full_messages.join(', ')}"
        end
        success
      end

      # boat spec that is not managed
      def set_missing_attr(attr, value)
        @missing_spec_attrs ||= {}
        @missing_spec_attrs[attr.to_s] = value
      end

      def get_missing_attr(attr)
        @missing_spec_attrs[attr.to_s]
      end

      private

      def adjust_location(target)
        if location.blank? && country.blank?
          # take info from office
          if office.present?
            target.country_id = office[:address_attributes].try(:[], :country_id)
            target.geo_location = office[:address_attributes].try(:[], :town_city)
          end
          # otherwise take info from user itself
          if target.geo_location.blank? && target.country_id.blank?
            broker_address = user.address
            target.country_id = broker_address.try(:country_id)
            target.geo_location = broker_address.try(:city_town)
          end
          return
        end

        if country.to_s.downcase == location.to_s.downcase
          self.location = ''
        end

        if country.to_s.downcase == 'uk'
          self.country = 'GB'
        end
        full_location = [location.to_s, country.to_s].reject(&:blank?).join(', ').downcase.strip
        if full_location != target.geo_location
          _country = nil
          if country.present?
            q = Country.joins("LEFT JOIN misspellings ON misspellings.source_id = countries.id AND misspellings.source_type = 'Country'")
            q = q.where('misspellings.alias_string = :name OR countries.name = :name OR countries.iso = :name', name: country)
            _country = q.first
          end
          if _country
            target.country = _country
            target.geo_location = full_location
          else
            # Geocoder.configure(
            #   http_proxy: 'http://uk.proxymesh.com:31280',
            #   timeout: 15
            # )

            geo_result = Geocoder.search(full_location, lookup: :google).first
            if geo_result && geo_result.country
              self.country = geo_result.country_code
              rcc = "#{Regexp.escape(geo_result.country_code)}|#{Regexp.escape(geo_result.country)}"
              self.location = full_location.gsub(/[\s,]*(#{rcc})[^\w]*$/i, '')
              target.geo_location = full_location
              self.update_country = true
            end
          end

          if update_country
            target.country = Country.find_by_iso(country) if country.present?
            if !target.country && country.present?
              target.country = Country.where('name LIKE ?', "#{country}%").first
            end
          end

          target.location = location
          if target.country
            rcc = "#{Regexp.escape(target.country.iso)}|#{Regexp.escape(target.country.name)}"
            target.location = location.to_s.gsub(/[\s,]*(#{rcc})[^\w]*$/i, '')
          else
            target.location = location.to_s.gsub(/[\s,]+$/, '')
          end
        end
      end

      def remove_contact_info!(str)
        # email
        str.gsub!(/\s+[^.,?!]*(email)?[^.,?!]*[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}[^.?!]*[.?!]/i, '')
        # phone number
        str.gsub!(/\s+[^.,?!]*(call)?[^.,?!]*[\d\-\s\(\)]{9,20}[^.?!]*[.?!]/i, '')
        # url
        str.gsub!(/\s+[^.,?!]*(:?http|https|ftp):\/\/[a-z0-9.-]+\.[a-z]{2,4}(:[a-z0-9]*)?\/?([a-z0-9._\?,'\\+&;%\$#=~"-])*/i, '')
        str
      end

    end
  end
end