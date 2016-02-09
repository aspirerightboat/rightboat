require 'nokogiri'
require 'rightboat/imports/utils' # fix "Circular dependency" error while running multithreaded import

module Rightboat
  module Imports
    class SourceBoat
      include ActionView::Helpers::TextHelper # for simple_format
      include ActiveModel::Validations
      include Utils

      validates_presence_of :user, :source_id, :manufacturer, :model

      NORMAL_ATTRIBUTES = [
        :source_id, :name, :description, :short_description, :poa, :price, :year_built, :offer_status, :length_m,
        :new_boat, :source_url, :owners_comment
      ]

      SPEC_ATTRS = [
        :hull_type, :hull_shape, :hull_material, :hull_color, :hull_construction, :hull_number, :hull_painting, :hull_painting_year,
        :flybridge, :air_conditioning, :stern_thruster, :bow_thruster, :bridge, :rig, :cockpit_type,
        :range, :lwl_m, :draft_m, :country_built, :displacement_net, :displacement_gross, :displacement_kgs,
        :engine_count, :engine_type, :engine_location, :engine_horse_power, :engine_hours, :engine, :engine_code, :engine_year,
        :ballast, :ballast_weight, :electrical_circuit, :max_speed, :cruising_speed, :beam_m,
        :fresh_water_tanks, :water_tanks_capacity, :holding_tanks, :holding_tanks_capacity,
        :heads, :berths, :single_berths, :double_berths, :twin_berths, :triple_berths, :cabins, :keel, :keel_type, :keel_code,
        :fuel_tanks, :fuel_tanks_capacity, :designer, :head_room, :builder, :length_on_deck, :propeller, :propeller_type, :propeller_code,
        :dry_weight, :passengers, :bathrooms, :gps, :gps_year, :vhf, :vhf_year, :plotter, :plotter_year,
        :radar, :radar_year, :battery_charger, :generator, :generator_kw, :inverter, :bimini,
        :cd_player, :cd_year, :dvd_player, :dvd_year, :cylinders, :gearbox,
        :known_defects, :last_serviced, :air_draft, :tv, :tv_year, :cabin_headroom,
        :super_structure_colour, :super_structure_construction, :deck_colour, :deck_construction, :deck_material, :spray_hood,
        :control_type, :oven, :microwave, :fridge, :freezer, :heating, :engine_tankage, :gallons_per_hour,
        :litres_per_hour, :starting_type, :cooling_system, :navigation_lights, :compass, :compass_year,
        :depth_instrument, :wind_instrument, :autopilot, :speed_instrument, :toilet, :shower, :bath, :life_raft, :life_raft_age,
        :epirb, :bilge_pump, :fire_extinguisher, :mob_system, :genoa, :genoa_furling, :genoa_cover, :tri_sail, :storm_jib,
        :main_sail, :winches, :battery, :shore_power, :fenders, :anchor, :seating_capacity, :drive_transmission_description,
        :dinette_sleeps, :crew_cabins, :crew_berths, :echosounder, :steering_system, :compartments, :desalinator,
        :jib, :jib_furling, :main_sail_furling, :main_sail_battened, :masts, :economy_speed, :trim_tabs, :shore_inverter,
        :speed_log, :wind_speed_dir, :steering_indicator, :dual_station_navigation, :magnetic_compass, :searchlight,
        :license, :date_of_refit, :wheel_steering, :bow_sprit, :warranty, :deadrise, :winter, :winter_cover,
        :windscreen_cover, :windscreen_wipers, :windlass, :windlass_year, :windlass_name, :windlass_code, :windlass_power, :wind_generator,
        :washing_machine, :vcr, :upholstery_replacement, :upholstery_replacement_year, :trailor, :trailor_year, :toerail_name, :toerail_code, :tiller,
        :teak_swimming_platform, :teak_side_decks, :teak_cockpit_table, :teak_cockpit, :swimming_platform, :swimming_ladder,
        :surveyed, :sun_cover, :stern_sunbathing, :steering_wheel, :steering_wheel_cover, :stay, :spray_hood,
        :spinnaker, :spinnaker_sock, :spinnaker_rigging, :spinnaker_pole, :solent, :solar_panels, :solar_panels_year, :shore_power_inlet,
        :seawater_pump, :saloon, :rod_holders, :rig_code, :repeater, :repeater_year, :windspeed, :windspeed_year, :winch_cover,
        :removable_cockpit_table, :radiotape_player_year, :radiotape_player, :radar_detector, :radar_detector_year, :radar_reflector,
        :power_24v, :power_220v, :power_12v, :power_110v, :power, :pilothouse_cover, :photos,
        :panelcontrol_cover, :outsidewindow_covers, :outboardengine_cover, :outboardengine_brackets, :othersails,
        :number_cockpit_cushions, :number_seawater_pump, :nb_spreader_levels, :navcenter_year, :navcenter,
        :motor_tiller, :motor_steering_wheel, :motor_boat_name, :mooring_cover, :draft_min, :draft_max, :drive_up,
        :material_code, :mast_pulpit, :marine_heads, :manual_bilge_pump, :mainsheet_traveller,
        :mainsail_furler, :mainsail_cover, :mainsail_cars, :mainsail, :log_year, :log,
        :leather_covered_steering_wheel, :lazyjacks, :lazybag, :launching_trailor, :launching_trailor_year, :inverter_year,
        :icebox, :hydraulic_gangway, :hydraulic_winch, :hot_cockpit_shower, :halyards_cockpit,
        :gennaker, :generator_year, :generator_power, :gangway_year, :gangway, :fullbattened,
        :freshwatermaker_year, :freshwatermaker_number, :freshwatermaker, :foresunbathing, :flyingstay,
        :flybridge_cover, :flaps, :fishing_depth_sounder, :fishing_depth_sounder_year, :engine_year_built, :engine_type_name,
        :electronicchart_year, :electronicchart, :electric_winch, :electricheads_number, :electricheads,
        :electric_bilge_pump, :dishwasher, :diesel_code, :depth_sounder, :depth_sounder_year,
        :deck_name, :deck_code, :davits, :cutlery, :crockery, :cooker, :computer_year,
        :computer, :compressor, :cockpit_cover, :cockpit_table_cover, :cockpit_table, :cockpit_speakers,
        :cockpit_shower, :cockpit_lightning, :cockpit_cushions, :chemical_heads, :chart_table,
        :cabriolet_dodger, :burner_stove, :bridge_clearance, :boiler,
        :fishing_chair, :beaching_legs, :battery_charger_number,
        :battened, :barbecue, :backstay, :autopilot_year, :anti_uv_strips, :anti_osmosis_treatment, :anti_osmosis_treatment_year, :antifouling_year,
        :antifouling, :antenna_year, :antenna, :alternator, :alternator_year, :air_conditioning_year,
        :fuel_water_tanks, :head_year, :fuel_water_tanks_number, :fresh_water_tanks_number, :heat_year,
        :fridge_capacity, :rope_cutter, :dinghy, :dinghy_year, :dinghy_type, :dinghy_engine, :dinghy_engine_power, :regata, :number_people,
        :working, :free_board
      ]

      RELATION_ATTRIBUTES = [
        :drive_type, :currency, :manufacturer, :model, :fuel_type, :vat_rate, :engine_manufacturer, :engine_model, :boat_type, :category
      ]

      DYNAMIC_ATTRIBUTES = [
        :import, :error_msg, :user, :images, :images_count, :new_record, :tax_status, :update_country, :country, :location,
        :office, :office_id, :target, :importer
      ]

      attr_reader :missing_spec_attrs
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

        search = Boat.solr_search do
          with :manufacturer_model, mnm
          order_by :live, :desc
          paginate per_page: 1
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
        cleanup_model

        return false if !valid?

        user_id = user.respond_to?(:id) ? user.id : user
        self.target = Boat.where(user_id: user_id, source_id: source_id).first_or_initialize
        target.import = import

        adjust_location(target)

        NORMAL_ATTRIBUTES.each do |attr_name|
          value = send(attr_name)
          case attr_name
          when :description
            target.description = cleanup_description(value)
          when :short_description
            target.short_description = cleanup_short_description(short_description || target.description)
          when :new_boat
            target.new_boat = value.present? && value.is_a?(String) ? (value =~ /\A(?:New|N)\z/).present? : value
          else
            target.send("#{attr_name}=", value) if value.present?
          end
        end
        # target.revive(true) if target.deleted?

        handle_specs

        if @missing_spec_attrs.present?
          importer.log_warning 'Unknown Spec Attrs', @missing_spec_attrs.map { |k, v| "#{k}: #{v}" }.join("\n")
        end

        RELATION_ATTRIBUTES.each do |attr_name|
          klass = Boat.reflections[attr_name.to_s].klass
          value = instance_variable_get("@#{attr_name}".to_sym)
          unless value.is_a?(ActiveRecord::Base)
            if value.blank? || value.to_s =~ /^[\.0]+$/
              value = nil
            elsif attr_name == :currency
              value = 'USD' if value == '$' # there are other currencies with $ symbol: AUD, CAD, HKD, NZD, SGD but USD is by default
              val = Currency.where('name = ? OR symbol = ?', value, value).first
              log_error 'Unknown Currency', "#{value}" if !val
              value = val
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
          importer.jobs_mutex.synchronize do
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
        elsif office_id
          target.office_id = office_id
        end

        target.poa = price.blank? || price.to_i <= 0

        self.images_count = 0
        boat_images_by_url = (target.boat_images.index_by(&:source_url) if target.persisted?)

        images.each do |url|
          url.strip!
          img = (boat_images_by_url[url] if target.persisted?) || BoatImage.new(source_url: url, boat: target)
          img.cache_file_from_source_url
          if target.new_record?
            if img.file_exists?
              target.boat_images << img
              self.images_count += 1
            end
          else
            success = img.save
            self.images_count += 1 if success
          end
        end

        self.new_record = target.new_record?

        target.save
      end

      def handle_specs
        new_specs_hash = SPEC_ATTRS.each_with_object({}.with_indifferent_access) do |spec_name, h|
          spec_name_str = spec_name.to_s
          value = send(spec_name).presence
          value = nil if value.to_s =~ /^(?:[0.]+|false|no)$/i
          if value && value.to_s =~ /^(?:true|1|yes)$/i
            if value == '1' && (spec_name_str.end_with?('_count') || spec_name_str.in?(%w(cabins crew_cabins heads berths single_berths double_berths twin_berths triple_berths)))
              # leave numerical value
            else
              value = 'Yes'
            end
          end
          h[spec_name_str] = value if value
        end

        # ensure spec records exists
        importer.jobs_mutex.synchronize do
          @@spec_id_by_name ||= Specification.pluck(:name, :id).to_h
          new_specs_hash.each_key do |name|
            @@spec_id_by_name[name] ||= Specification.create(name: name, display_name: name.titleize).id
          end
        end

        # crud boat specs
        if target.new_record?
          new_specs_hash.each { |name, value| target.boat_specifications.build(specification_id: @@spec_id_by_name[name], value: value) }
        else
          existing_specs = target.boat_specifications.specs_hash

          create_specs = new_specs_hash.except(*existing_specs.keys)
          create_specs.each { |name, value| target.boat_specifications.create(specification_id: @@spec_id_by_name[name], value: value) }
          delete_spec_names = existing_specs.keys - new_specs_hash.keys
          target.boat_specifications.where(specification_id: delete_spec_names.map { |name| @@spec_id_by_name[name] }).delete_all if delete_spec_names.any?
          update_specs = new_specs_hash.except(*create_specs.keys)
          update_specs.each { |name, value| target.boat_specifications.where(specification_id: @@spec_id_by_name[name]).update_all(value: value) if existing_specs[name] != value }
        end
      end

      def set_missing_attr(attr, value)
        @missing_spec_attrs ||= {}
        @missing_spec_attrs[attr.to_s] = value
      end

      def get_missing_attr(attr)
        @missing_spec_attrs[attr.to_s]
      end

      private

      def cleanup_model
        self.model = 'Unknown' if model.blank?
        model.gsub!(/#{Regexp.escape(manufacturer)}\s+/i, '') if manufacturer && model.is_a?(String)
      end

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

      def do_import_substitutions!(value)
        import_subs.each { |is| is.process_text!(value) }
      end

      def import_subs
        @@import_subs ||= {}
        @@import_subs[import.import_type] ||= begin
          import_type = ['', import.import_type]
          id = ['', import.id]
          ImportSub.where(import_type: import_type, import_id: id).select(:use_regex, :from, :to).to_a
        end
      end

      ALLOWED_TAGS = %w(p br i b strong h3 ul ol li)

      def cleanup_description(str)
        return '' if str.blank?
        str = simple_format(str) if !str['<']
        body = Nokogiri::HTML(str).at_css('body')
        body.css('table').remove

        body.traverse do |node|
          if node.elem? && node != body
            tag_name = node.name
            if tag_name.in?(ALLOWED_TAGS)
              node.each { |attr, _| node.delete(attr) }
              node.remove if tag_name == 'p' && node.text.blank?
            else
              node.replace(node.children)
            end
          end
        end
        str = body.inner_html(save_with: 0) # save_with: 0 to remove newlines between tags
        str.gsub!(Rightboat::Imports::Utils::WHITESPACES_REGEX, ' ')
        str.strip!
        do_import_substitutions!(str)
        str
      end

      def cleanup_short_description(desc)
        return '' if desc.blank?
        # desc = desc[%r{<p>[^<]+</p>}] || desc
        desc = desc[0..480]
        desc = desc.sub(/[^>.!]+\z/, '').presence || "#{desc}..."
        desc.gsub!(/\S+@\S(?:\.\S)+/, '') # remove email
        desc.gsub!(/[\d\(\) -]{9,20}/, '') # remove phone
        desc.gsub!(%r{(?:https?://|www\.)\S+}, '') # remove url
         Nokogiri::HTML.fragment(desc).to_html
      end

    end
  end
end