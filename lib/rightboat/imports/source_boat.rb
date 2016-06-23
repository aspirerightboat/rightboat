require 'nokogiri'
require 'rightboat/imports/utils' # fix "Circular dependency" error while running multithreaded import
require 'rightboat/make_model_splitter'
require 'xxhash'

module Rightboat
  module Imports
    class SourceBoat
      include ActionView::Helpers::TextHelper # for simple_format
      include ActiveModel::Validations
      include Utils

      validates_presence_of :user, :source_id, :manufacturer, :model

      NORMAL_ATTRIBUTES = [
        :source_id, :name, :description, :short_description, :poa, :price, :year_built, :offer_status,
        :length_m, :length_f, :new_boat, :source_url, :owners_comment
      ]

      SPEC_ATTRS = [
        :agreement_type, :air_conditioning, :air_conditioning_make, :air_conditioning_year, :air_draft_m,
        :alternator, :alternator_make, :alternator_year, :anchor, :antenna, :antenna_year,
        :anti_osmosis_treatment, :anti_osmosis_treatment_year,:anti_uv_strips, :antifouling, :antifouling_year,
        :autopilot, :autopilot_year,
        :backstay, :backstay_count, :ballast_kgs, :barbecue, :bath, :bathrooms,
        :battened, :battened_count, :battery, :battery_charger, :battery_charger_number, :beaching_legs, :beam_m,
        :berths_count, :double_berths_count, :single_berths_count, :triple_berths_count, :twin_berths_count,
        :bilge_pump, :bimimi, :bimini, :boiler, :bow_sprit, :bow_sprit_count, :bow_thruster, :bridge, :bridge_clearance, :bridge_clearance_meters,
        :builder, :builder_length_meters, :burner_stove, :cabin_headroom, :cabins_count, :cabriolet_dodger, :captain_on_board, :captain_quarters,
        :cd_count, :cd_player, :cd_year, :chart_table, :chemical_heads, :classifications,
        :cockpit, :cockpit_cover, :cockpit_cushions, :cockpit_lightning, :cockpit_shower, :cockpit_speakers, :cockpit_table,
        :cockpit_table_cover, :cockpit_type, :compartments, :compass, :compass_year, :compressor,
        :computer, :computer_count, :computer_makemodel, :computer_year,
        :control_type, :cooker, :cooling_system, :cooling_system_type, :country_built,
        :crew_berths_count, :crew_cabins_count, :crockery,
        :cruise_speed_mph, :cruising_speed, :cruise_speed_rpm,
        :cutlery, :cylinders_count, :date_of_refit, :davits, :deadrise,
        :deck_code, :deck_colour, :deck_construction, :deck_material, :deck_name, :length_on_deck,
        :degree, :degree_reefsystem, :depth_instrument, :depth_sounder, :depth_sounder_year,
        :desalinator, :designer, :diesel_code, :differential, :differential_reefsystem, :dinette_sleeps,
        :dinghy, :dinghy_engine, :dinghy_engine_power, :dinghy_type, :dinghy_year,
        :dishwasher, :displacement_gross, :displacement_kgs, :displacement_net,
        :draft_m, :draft_max, :draft_min, :drive_transmission_description, :drive_up, :dry_weight, :dual_station_navigation,
        :dvd_count, :dvd_player, :dvd_year, :echosounder, :economy_speed,
        :electric_bilge_pump, :electric_winch, :electrical_circuit, :electricheads, :electricheads_number, :electronicchart, :electronicchart_year,
        :engine, :engine_code, :engine_count, :engine_date_hours_registered1, :engine_horse_power, :engine_horse_power2, :engine_horse_power3,
        :engine_hours, :engine_hours2, :engine_hours3, :engine_year3,
        :engine_location, :engine_range_nautical_miles, :engine_tankage, :engine_type, :engine_type_name, :engine_year, :engine_year2, :engine_year_built,
        :epirb, :fenders, :fire_extinguisher, :fire_extinguisher_type, :fishing_chair, :fishing_depth_sounder, :fishing_depth_sounder_year,
        :flag, :flaps, :fly_bridge, :flybridge, :flybridge_cover,
        :flyingstay, :foresunbathing, :freeboard, :freezer,
        :fresh_water_tanks, :fresh_water_tanks_number, :freshwatermaker, :freshwatermaker_number, :freshwatermaker_year,
        :fridge, :fridge_capacity,
        :fuel_capacity_gal, :fuel_consumption_gal, :fuel_consumption_ltr, :fuel_tanks, :fuel_tanks_capacity,
        :fuel_water_tanks, :fuel_water_tanks_number, :fullbattened, :fullbattened_count, :gallons_per_hour, :gangway, :gangway_year, :gearbox,
        :generator, :generator_kw, :generator_power, :generator_year,
        :gennaker, :gennaker_characs, :genoa, :genoa_cover, :genoa_furling, :genoa_material, :genoa_reefsystem,
        :gps, :gps_year, :gross_tonnage, :half_winder_bollejan, :halyards_cockpit,
        :hardwood_rigging, :head_room, :head_year, :heads_count, :heads_count, :heat_year,
        :heating, :heating_type, :helipad, :holding_tank_gal, :holding_tanks, :holding_tanks_capacity, :hot_cockpit_shower,
        :hull_color, :hull_configuration, :hull_construction, :hull_designer, :hull_fuel_tank_material, :hull_id, :hull_material,
        :hull_number, :hull_painting, :hull_painting_year, :hull_shape, :hull_type, :hull_water_tank_material,
        :hydraulic_gangway, :hydraulic_winch, :icebox,
        :inverter, :inverter_year, :jib, :jib_furling, :keel, :keel_code, :keel_type, :known_defects, :last_serviced,
        :launching_trailor, :launching_trailor_year, :lazybag, :lazyjacks, :leather_covered_steering_wheel, :license,
        :life_raft, :life_raft_age, :life_raft_capacity,
        :listing_date, :litres_per_hour, :lod_meters, :log, :log_count, :log_year, :lwl_m, :magnetic_compass,
        :mainsail, :mainsail_battened, :mainsail_cars, :mainsail_cover, :mainsail_count, :mainsail_furler, :mainsail_furling, :mainsail_material, :mainsail_reefsystem,
        :mainsheet_traveller, :manual_bilge_pump, :marine_heads, :mast_pulpit, :masts, :material_code,
        :max_draft_meters, :max_load_capacity, :max_speed_knots, :max_speed_mph, :max_speed_rpm, :microwave, :mob_system, :mob_system_type,
        :model_year, :mooring_cover, :motor_boat_name, :motor_steering_wheel, :motor_tiller,
        :navcenter, :navcenter_year, :navigation_lights, :nb_spreader_levels, :not_for_sale_in_us,
        :num_sleeps, :number_cockpit_cushions, :number_people, :number_seawater_pump, :othersails,
        :outboardengine_brackets, :outboardengine_cover,
        :outsidewindow_covers, :oven, :panelcontrol_cover, :passengers_count, :pdf_url, :photos, :pilothouse_cover,
        :plotter, :plotter_year, :power, :power_110v, :power_12v, :power_220v, :power_24v,
        :profile_url, :propeller, :propeller_code, :propeller_type,
        :radar, :radar_detector, :radar_detector_year, :radar_reflector, :radar_year, :remaining,
        :radiotape_player, :radiotape_player_year, :range, :reg_details, :regata, :removable_cockpit_table,
        :repeater, :repeater_count, :repeater_makemodel, :repeater_year,
        :rig, :rig_code, :rod_holders, :rope_cutter, :saloon, :scissors, :searchlight, :seating_capacity, :seating_system,
        :sailing_equipment, :seawater_pump, :shore_inverter, :shore_power, :shore_power_inlet, :shower, :solar_panels, :solar_panels_year, :solent,
        :speed_instrument, :speed_log, :spinnaker, :spinnaker_material,
        :spinnaker_pole, :spinnaker_rigging, :spinnaker_rigging_count, :spinnaker_sock,
        :spray_hood, :starting_type, :state_rooms, :stay,
        :steering_indicator, :steering_system, :steering_wheel, :steering_wheel_cover,
        :stern_sunbathing, :stern_thruster, :storm_jib, :storm_jib_material, :stormfox, :sub_category, :sun_cover,
        :super_structure_colour, :super_structure_construction, :support_sail, :surveyed, :swimming_ladder, :swimming_platform,
        :teak_cockpit, :teak_cockpit_table, :teak_side_decks, :teak_swimming_platform,
        :tiller, :toerail_code, :toerail_name, :toilet, :trailor, :trailor_year, :tri_sail, :tri_sail_material,
        :trim_tabs, :tv, :tv_year, :upholstery_replacement, :upholstery_replacement_year,
        :vcr, :vessel_top, :vhf, :vhf_year, :videos, :warranty, :washing_machine, :water_capacity_gal, :water_tanks_capacity,
        :weight_pounds, :weight_short_ton, :weight_tonne, :wheel_steering, :where_built,
        :winch_cover, :winch_handles, :winches_count, :wind_generator, :wind_instrument, :wind_speed_dir,
        :windlass, :windlass_code, :windlass_name, :windlass_power, :windlass_year,
        :windscreen_cover, :windscreen_wipers, :windspeed, :windspeed_count, :windspeed_makemodel, :windspeed_year,
        :winter, :winter_cover, :working
      ]

      RELATION_ATTRIBUTES = [
        :drive_type, :currency, :manufacturer, :model, :fuel_type, :vat_rate, :engine_manufacturer, :engine_model, :boat_type, :category
      ]

      DYNAMIC_ATTRIBUTES = [
        :import, :error_msg, :user, :images, :pending_images_count, :new_record, :tax_status, :update_country, :country, :location,
        :office, :office_id, :target, :importer, :class_groups
      ]

      attr_reader :missing_spec_attrs
      attr_accessor *DYNAMIC_ATTRIBUTES
      attr_accessor *SPEC_ATTRS
      attr_accessor *NORMAL_ATTRIBUTES
      attr_accessor *RELATION_ATTRIBUTES

      (NORMAL_ATTRIBUTES + SPEC_ATTRS + DYNAMIC_ATTRIBUTES + RELATION_ATTRIBUTES).each do |attr_name|
        define_method "#{attr_name}=" do |v|
          v.ensure_utf8!.squeeze_whitespaces!.strip! if v.is_a?(String)
          instance_variable_set :"@#{attr_name}", v
        end
      end

      # some sources has only merged string instead of separate manufacturer/model
      # in this case, search solr and find first
      # if not exists in solr, use split method
      # e.g. yachtworld: Marine Projects Sigma 38, Alloy Yachts Pilothouse
      def manufacturer_model=(mnm)
        return if mnm.blank?

        self.manufacturer, self.model, success = Rightboat::MakeModelSplitter.split(mnm)

        if !success
          importer.log_warning 'Cannot guess manufacturer for sure',
                               %(make_model_str="#{mnm}" guessed_maker="#{manufacturer}" guessed_model="#{model}")
        end
      end

      def initialize(attrs = {})
        attrs.each do |k, v|
          send "#{k}=", v
        end
      end

      def save
        cleanup_make_model

        return false unless valid?

        user_id = user.respond_to?(:id) ? user.id : user
        self.target = Boat.where(user_id: user_id, source_id: source_id, import_id: import.id).first_or_initialize

        adjust_location(target)

        NORMAL_ATTRIBUTES.each do |attr_name|
          value = send(attr_name)
          case attr_name
          when :description
            target.description = cleanup_description(value)
          when :short_description
            target.short_description = cleanup_short_description(short_description || description || target.description)
          when :new_boat
            target.new_boat = value.present? && value.is_a?(String) ? (value =~ /\A(?:New|N)\z/i).present? : value
          when :poa
            target.poa = value
          else
            target.send("#{attr_name}=", value) if value.present?
          end
        end

        handle_specs
        handle_class_groups

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
              importer.log_error 'Unknown Currency', "#{value}" if !val
              value = val
            else
              # if attr_name == :manufacturer || attr_name == :model
              #   value = value.titleize
              # end

              if attr_name == :model
                query_option = {manufacturer_id: target.manufacturer_id}
              elsif attr_name == :engine_model
                query_option = {engine_manufacturer_id: target.engine_manufacturer_id}
              else
                query_option = {}
              end
              # value = klass.find_by(name: value)
              # value ||= Misspelling

              value = klass.query_with_aliases(value).where(query_option).create_with(query_option).first_or_create!
            end
          end

          target.send "#{attr_name}=", value
        end

        handle_office

        target.poa ||= price.blank? || price.to_i <= 0
        target.deleted_at = nil if target.deleted?
        self.new_record = target.new_record?
        self.pending_images_count = images.size

        saved = target.save

        if saved && images.present?
          images_job = ImportBoatImagesJob.new(importer.import_trail.id, target.id, images, importer.images_proxy_url)
          if ENV['INLINE_IMPORT_IMAGES']
            images_job.perform
          else
            priority = new_record ? 0 : 10 # 0 has higher priority
            Delayed::Job.enqueue images_job, queue: 'import_images', priority: priority
          end
        end

        saved
      end

      def handle_specs
        new_specs_hash = SPEC_ATTRS.each_with_object({}.with_indifferent_access) do |spec_name, h|
          spec_name_str = spec_name.to_s
          value = send(spec_name).presence
          if spec_name_str.end_with?('_count')
            # leave numerical value
          else
            value = nil if value.to_s =~ /^(?:[0.]+|false|no)$/i

            if value && value.to_s =~ /^(?:true|1|yes)$/i
              value = 'Yes'
            end
          end
          h[spec_name_str] = value if value
        end

        # ensure spec records exists
        importer.jobs_mutex.synchronize do
          @@spec_id_by_name ||= begin
            misspellings_hash = Misspelling.where(source_type: 'Specification').pluck(:alias_string, :source_id).to_h
            misspellings_hash.merge!(Specification.pluck(:name, :id).to_h)
          end
          new_specs_hash.each_key do |name|
            @@spec_id_by_name[name] ||= Specification.create(name: name, display_name: name.titleize).id
          end
        end

        # crud boat specs
        if target.new_record?
          new_specs_hash.each do |name, value|
            target.boat_specifications.build(specification_id: @@spec_id_by_name[name], value: value)
          end
        else
          existing_boat_specs = target.boat_specifications.includes(:specification).to_a
          existing_spec_names = existing_boat_specs.map { |bs| bs.specification.name }

          create_specs = new_specs_hash.except(*existing_spec_names)
          create_specs.each do |name, value|
            target.boat_specifications.create(specification_id: @@spec_id_by_name[name], value: value)
          end

          delete_spec_names = existing_spec_names - new_specs_hash.keys
          delete_spec_names.each do |name|
            bs = existing_boat_specs.find { |bs| bs.specification.name == name }
            bs.destroy(:force)
          end

          update_specs = new_specs_hash.except(*create_specs.keys)
          update_specs.each do |name, value|
            bs = existing_boat_specs.find { |bs| bs.specification.name == name }
            bs.value = value
            bs.deleted_at = nil
            bs.save! if bs.changed?
          end
        end
      end

      def handle_class_groups
        return if class_groups.blank?

        class_groups_hash = {}
        class_groups.each do |x|
          class_groups_hash[x[:class_code]] = x[:primary]
        end

        importer.jobs_mutex.synchronize do
          @@class_codes ||= BoatClassCode.pluck(:name, :id).to_h
          class_groups.each do |x|
            name = x[:class_code]
            @@class_codes[name] ||= BoatClassCode.create(name: name).id
          end
        end

        if target.new_record?
          class_groups.each do |x|
            target.class_groups.build(class_code_id: @@class_codes[x[:class_code]], primary: x[:primary])
          end
        else
          existing_class_groups = target.class_groups.includes(:class_code).to_a
          existing_code_names = existing_class_groups.map { |x| x.class_code.name }

          create_groups = class_groups_hash.except(*existing_code_names)
          create_groups.each do |name, value|
            target.class_groups.create(class_code_id: @@class_codes[name], primary: value)
          end

          delete_code_names = existing_code_names - class_groups_hash.keys
          delete_code_names.each do |name|
            x = existing_class_groups.find { |x| x.class_code.name == name }
            x.destroy(:force)
          end

          update_class_groups = class_groups_hash.except(*create_groups.keys)
          update_class_groups.each do |name, value|
            x = existing_class_groups.find { |x| x.class_code.name == name }
            x.primary = value
            x.deleted_at = nil
            x.save! if x.changed?
          end
        end
      end

      def set_missing_attr(attr, value)
        @missing_spec_attrs ||= {}
        @missing_spec_attrs[attr.to_s] = value
      end

      def get_missing_attr(attr)
        @missing_spec_attrs[attr.to_s]
      end

      def handle_office
        if office.present?
          importer.jobs_mutex.synchronize do
            @@user_offices ||= user.offices.includes(:address).to_a

            address_attrs = office.delete(:address_attributes)

            office_id = office[:source_id]
            if office[:source_id].blank?
              office_id = XXhash.xxh32(office.each_with_object('') { |(k, v), s| s << "#{k}#{v}" }).to_s
            end

            target_office = @@user_offices.find { |o| o.source_id.present? && o.source_id == office_id }
            target_office ||= @@user_offices.find { |o| o.source_id.blank? && office.all? { |k, v| o.send(k) == v } }
            target_office ||= user.offices.new

            target_office.assign_attributes(office)
            target_office.source_id = office_id
            target_office.name ||= user.company_name
            address = target_office.address || Address.new
            address.assign_attributes(address_attrs) if address_attrs
            office_changed = target_office.changed?
            address_changed = address.changed?

            if office_changed || address_changed
              new_record = target_office.new_record?
              target_office.save! if office_changed
              address.save! if !new_record && address_changed
              @@user_offices << target_office if new_record
            end

            target.office = target_office
          end
        elsif office_id
          target.office_id = office_id
        end
      end

      private

      def cleanup_make_model
        if model && model.is_a?(String) && manufacturer && manufacturer.is_a?(String)
          model.gsub!(/#{Regexp.escape(manufacturer)}/i, '')
          model.strip!
          manufacturer.gsub!(/#{Regexp.escape(model)}/i, '')
          manufacturer.strip!
        end

        if manufacturer && manufacturer.is_a?(String)
          if manufacturer =~ /\d/ && !Manufacturer.where(name: manufacturer).exists? || model.blank?
            self.manufacturer_model = manufacturer
          end
        end

        self.model = 'Unknown' if model.blank?
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

          if target.country
            rcc = "#{Regexp.escape(target.country.iso)}|#{Regexp.escape(target.country.name)}"
            target.location = location.to_s.gsub(/[\s,]*(#{rcc})[^\w]*$/i, '')
          else
            target.location = location.to_s.gsub(/[\s,]+$/, '')
          end
        end

        # ensure location not include broker company name
        # eg. Burton Waters Marina Limited
        name_rcc = target.user.company_name.gsub(/(Marina Limited)/i, '').strip
        target.location = target.location.gsub(/(#{name_rcc})([\s,]+)?/i, '')
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

        frag = Nokogiri::HTML.fragment(str)
        frag.css('table').remove

        frag.traverse do |node|
          if node.elem? && node != frag
            tag_name = node.name
            if tag_name.in?(ALLOWED_TAGS)
              node.each { |attr, _| node.delete(attr) }
              node.remove if tag_name == 'p' && node.text.blank?
            else
              node.replace(node.children)
            end
          end
        end
        str = frag.to_html
        do_import_substitutions!(str)
        str
      rescue LoadError => e
        if Rails.env.development?
          # I have strange error here on "to_html" call when run with multiple threads but on prod works ok
          # LoadError: dlopen(enc/trans/single_byte.so, 9): image not found - enc/trans/single_byte.so
          importer.log "Dev Error: #{e.class.name}: #{e.message}. #{e.backtrace.join("\n")}\n==>#{source_id}. #{str}"
          str
        else
          raise e
        end
      end

      def cleanup_short_description(desc)
        return '' if desc.blank?
        desc = desc[0..480]
        while true
          if (pos = desc =~ /[^>.!]+\z/).nil?
            break
          end
          prev = pos - 1
          if desc[prev..pos] =~ /\.\d/
            desc = desc[0..(prev - 1)]
          else
            desc = desc[0..prev]
            break
          end
        end
        desc = "#{desc}..." if desc.blank?
        desc.gsub!(/\S+@\S(?:\.\S)+/, '') # remove email
        desc.gsub!(/[\d\(\) -]{9,20}/, '') # remove phone
        desc.gsub!(%r{(?:https?://|www\.)\S+}, '') # remove url
        Nokogiri::HTML.fragment(desc).to_html # ensure html is valid
      end

    end
  end
end
