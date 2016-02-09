module Rightboat
  module Imports
    module Sources
      class Eyb < Base
        def data_mapping
          @data_mapping ||= SourceBoat::SPEC_ATTRS.inject({}) { |h, attr| h[attr.to_s] = attr; h}.merge(
              'id' => :source_id,
              'boat_price' => :price,
              'currency_code' => :currency,
              'vat' => :vat_rate,
              'lying_country_name' => :country, # FR
              'lying_country_code' => '', # 55
              'lying_town' => :location, # AJACCIO
              'lying_harbour' => '', # PORT GINESTA
              'weight' => :dry_weight,
              'hull_name' => :hull_type,
              'model' => :model,
              'builder' => :manufacturer,
              'year_built' => :year_built,
              'name_boat' => :name,
              'length' => :length_m,
              'beam' => :beam_m,
              'draugth' => :draft_m,
              'number_engines' => :engine_count,
              'diesel' => :fuel_type,
              'engine_power' => :engine_horse_power,
              'engine_model' => :engine_model,
              'engine_make' => :engine_manufacturer,
              'hours_engine' => :engine_hours,
              'number_cabins' => :cabins,
              'comments' => :owners_comment,
              'exhibitcomments' => :description,
              'type_name' => :boat_type, # Motor boat
              'type' => '', # M
              'working' => :working,
              'working_characs' => :working,
              'winter_cover' => :winter_cover,
              'winter' => :winter,
              'windspeed_year' => :windspeed_year,
              'windspeed' => :windspeed,
              'windscreen_cover' => :windscreen_cover,
              'windscreenwipers' => :windscreen_wipers,
              'windlass_year' => :windlass_year,
              'windlass_name' => :windlass_name,
              'windlass_code' => :windlass_code,
              'windgenerator' => :wind_generator,
              'winch_handles' => :winches,
              'winch_cover' => :winch_cover,
              'washingmachine' => :washing_machine,
              'vhf_year' => :vhf_year,
              'vcr' => :vcr,
              'valid' => '',
              'upholstery_replacement' => :upholstery_replacement,
              'tv_year' => :tv_year,
              'tv' => :tv,
              'trailor' => :trailor,
              'toerail_name' => :toerail_name,
              'toerail_code' => :toerail_code,
              'tiller' => :tiller,
              'teak_swimmingplatform' => :teak_swimming_platform,
              'teaksidedecks' => :teak_side_decks,
              'teakcockpittable' => :teak_cockpit_table,
              'teakcockpit' => :teak_cockpit, # 1
              'swimmingplatform' => :swimming_platform, # 1
              'swimmingladder' => :swimming_ladder, # 1
              'surveyed' => :surveyed, # 0
              'sun_cover' => :sun_cover, # 0
              'stormjib' => :storm_jib, # 0
              'sternsunbathing' => :stern_sunbathing, # 1
              'steering_wheel' => :wheel_steering, # 1
              'steeringwheel_cover' => :steering_wheel_cover, # 1
              'stay' => :stay, # 1
              'sprayhood' => :spray_hood, # 0
              'spinnaker_sock' => :spinnaker_sock, # 0
              'spinnaker_rigging' => :spinnaker_rigging, # 0
              'spinnaker_pole' => :spinnaker_pole, # 0
              'spi' => :spinnaker, # 0
              'solent' => :solent, # 0
              'solarpanels' => :solar_panels, # 0
              'shorepowerinlet' => :shore_power_inlet, # 1
              'seawaterpump' => :seawater_pump, # 1
              'saloon' => :saloon, # 0
              'safetyfreecomments' => '', # MATERIAL SEGURIDAD ZONA 2
              'rodholders' => :rod_holders, # 0
              'rig_name' => :rig, # Cutter
              'rig_code' => :rig_code, # C
              'repeater' => :repeater, # 0
              'removablecockpittable' => :removable_cockpit_table, # 0
              'radiotapeplayer_year' => :radiotape_player_year, # 0
              'radiotapeplayer' => :radiotape_player, # 1
              'radar_year' => :radar_year, # 0
              'radarreflector' => :radar_reflector, # 1
              'radardetector' => :radar_detector, # 0
              'propeller_name' => :propeller, # Folding
              'propeller_code' => :propeller_code, # P
              'price_just_reduced' => '', # 0
              'power_24v' => :power_24v, # 0
              'power_220v' => :power_220v, # 1
              'power_12v' => :power_12v, # 0
              'power_110v' => :power_110v, # 0
              'power' => :power, # 1
              'plotter_year' => :plotter_year, # 0
              'pilothouse_cover' => :pilothouse_cover, # 0
              'photos' => '', # 10
              'panelcontrol_cover' => :panelcontrol_cover, # 0
              'outsidewindow_covers' => :outsidewindow_covers, # 0
              'outboardengine_cover' => :outboardengine_cover, # 0
              'outboardengine_brackets' => :outboardengine_brackets, # 1
              'othersails' => :othersails, # 0
              'oneoff' => '', # 0
              'number_heads' => :heads, # 2
              'number_cockpit_cushions' => :number_cockpit_cushions, # 0
              'number_births_3' => :triple_berths, # 0
              'number_births_2' => :double_berths, # 3
              'number_births_1' => :single_berths, # 0
              'number_births' => :berths, # 6
              'number_bathrooms' => :bathrooms, # 0
              'numberseawaterpump' => :number_seawater_pump, # 0
              'nb_spreaderlevels' => :nb_spreader_levels, # 3
              'navcenter_year' => :navcenter_year, # 0
              'navcenter' => :navcenter, # 1
              'motortiller' => :motor_tiller, # 0
              'motorsteeringwheel' => :motor_steering_wheel, # 0
              'mooring_cover' => :mooring_cover, # 0
              'modif_date' => '', # 2015/12/07
              'mindraft' => :draft_min, # 0
              'microwaveoven' => :microwave, # 0
              'mechanical_fridge' => :fridge, # 0
              'maxdraft' => :draft_max, # 0
              'material_name' => :hull_material, # Steel
              'material_code' => :material_code, # AC
              'mastpulpit' => :mast_pulpit, # 0
              'marineheads' => :marine_heads, # 0
              'manualbilgepump' => :manual_bilge_pump, # 0
              'main_sheet_traveller' => :mainsheet_traveller, # 1
              'mainsail_furler' => :mainsail_furler, # 0
              'mainsail_cover' => :mainsail_cover, # 0
              'mainsail_cars' => :mainsail_cars, # 1
              'mainsail' => :mainsail, # 1
              'log_year' => :log_year, # 0
              'log' => :log, # 1
              'leathercoveredsteeringwheel' => :leather_covered_steering_wheel, # 1
              'lazyjacks' => :lazyjacks, # 1
              'lazybag' => :lazybag, # 1
              'launching_trailor' => :launching_trailor, # 0
              'keel_name' => :keel, # Fixed Keel
              'keel_code' => :keel_code, # Q
              'inverter_year' => :inverter_year, # 0
              'input_date' => '', # 2013/02/09
              'initial_price' => '', # 800000
              'icebox' => :icebox, # 0
              'hydrolicgangway' => :hydraulic_gangway, # 0
              'hydraulic_winch' => :hydraulic_winch, # 0
              'hull_painting' => :hull_painting, # 0
              'hull_colour_name' => :hull_color, # Blue
              'hull_colour' => '', # BL
              'hull_code' => :hull_number, # M
              'hotcockpitshower' => :hot_cockpit_shower, # 0
              'heat' => :heating, # 0
              'headroom' => :head_room, # 0
              'halyards_cockpit' => :halyards_cockpit, # 1
              'gps_year' => :gps_year, # 0
              'gen_furler' => :genoa_furling, # 1
              'genoa_cover' => :genoa_cover, # 0
              'gennaker' => :gennaker, # 1
              'generator_year' => :generator_year, # 0
              'generator_power' => :generator_power, # 0
              'gangway_year' => :gangway_year, # 0
              'gangway' => :gangway, # 1
              'fullbattened' => :fullbattened, # 0
              'freshwatermaker_year' => :freshwatermaker_year, # 0
              'freshwatermaker_number' => :freshwatermaker_number, # 0
              'freshwatermaker' => :freshwatermaker, # 1
              'foresunbathing' => :foresunbathing, # 0
              'flyingstay' => :flyingstay, # 0
              'flybridge_cover' => :flybridge_cover, # 0
              'flaps' => :flaps, # 0
              'fishing_depth_sounder' => :fishing_depth_sounder, # 0
              'europrice' => '', # 410000
              'engine_year_built' => :engine_year, # 2008
              'engine_type_name' => :engine_type, # Inboard
              'electronicchart_year' => :electronicchart_year, # 0
              'electronicchart' => :electronicchart, # 1
              'electric_winch' => :electric_winch, # 5
              'electricheads_number' => :electricheads_number, # 0
              'electricheads' => :electricheads, # 1
              'electricbilgepump' => :electric_bilge_pump, # 0
              'dvd_year' => :dvd_year, # 0
              'dvd' => :dvd_player, # 1
              'dishwasher' => :dishwasher, # 1
              'dinghy_year_engine' => '', # 0
              'diesel_code' => :diesel_code, # D
              'depth_sounder_year' => :depth_sounder_year, # 0
              'depth_sounder' => :depth_sounder, # 1
              'deck_name' => :deck_name, # Teak
              'deck_code' => :deck_code, # T
              'davits' => :davits, # 0
              'cutlery' => :cutlery, # 0
              'currency' => '', # 0
              'crockery' => :crockery, # 0
              'cooker' => :cooker, # 1
              'computer_year' => :computer_year, # 0
              'computer' => :computer, # 1
              'compressor' => :compressor, # 0
              'compass_year' => :compass_year, # 0
              'cockpit_cover' => :cockpit_cover, # 0
              'cockpittable_cover' => :cockpit_table_cover, # 0
              'cockpittable' => :cockpit_table, # 1
              'cockpitspeakers' => :cockpit_speakers, # 1
              'cockpitshower' => :cockpit_shower, # 1
              'cockpitlightning' => :cockpit_lightning, # 1
              'cockpitcushions' => :cockpit_cushions, # 1
              'chemicalheads' => :chemical_heads, # 0
              'charttable' => :chart_table, # 1
              'cd_year' => :cd_year, # 0
              'cd' => :cd_player, # 1
              'cabrioletdodger' => :cabriolet_dodger, # 0
              'burnerstove' => :burner_stove, # 1
              'bridgeclearance' => :bridge_clearance, # 0
              'bowsprit' => :bow_sprit, # 0
              'boiler' => :boiler, # 1
              'boat_flag_country_name' => :country_built, # SPAIN
              'boat_flag_country_code' => '', # 77
              'biminitop' => :bimini, # 0
              'bilgepump' => :bilge_pump, # 1
              'biggamefishingchair' => :fishing_chair, # 0
              'beachinglegs' => :beaching_legs, # 0
              'battery_charger_number' => :battery_charger_number, # 0
              'battened' => :battened, # 1
              'barbecue' => :barbecue, # 0
              'backstay' => :backstay, # 1
              'autopilot_year' => :autopilot_year, # 0
              'autopilot_characs' => :autopilot, # ST 6000 PLUS
              'autopilot_makemodel' => :autopilot, # RAYMARINE ST 7000
              'antiuvstrips' => :anti_uv_strips, # 1
              'antiosmosistreatment' => :anti_osmosis_treatment, # 0
              'antifouling_year' => :antifouling_year, # 0
              'antifouling' => :antifouling, # 1
              'antenna_year' => :antenna_year, # 0
              'antenna' => :antenna, # 1
              'alternator' => :alternator, # 0
              'airconditioning_year' => :air_conditioning_year, # 0
              'airconditioning' => :air_conditioning, # 1
              'rodholdersnumber' => :rod_holders, # 4
              'motor_boat_type' => '', # C
              'motor_boat_name' => :motor_boat_name, # Cabin
              'marineheads_number' => :marine_heads, # 0
              'fuelwatertanks' => :fuel_water_tanks, # 1
              'fuelholdingtanks' => :fuel_tanks, # 1
              'freshwatertanks' => :fresh_water_tanks, # 1
              'fishing_depth_sounder_year' => :fishing_depth_sounder_year, # 0
              'Unknown ' => '', # windspeed_makemodel: RAYMARINE ST 60
              'vhf_makemodel' => '', # RAYMARINE
              'stay_characs' => :stay, # ENROLLABLE AUTOVIRANTE SANDWICH 27.4 m
              'othersails_characs' => :othersails, # VELAS NUEVAS DE 2013
              'number_cockpitcushions' => :number_cockpit_cushions, # 0
              'life_raft_type' => :life_raft, # 10 plazas
              'heat_year' => :heat_year, # 0
              'genoa_characs' => :genoa, # TRIRRADIAL EN SANDWICH 93.6M
              'generator_make' => :generator, # ONAN MASE IS 6.5-3
              'gangway_make' => :gangway, # FONTANEL EN POPA
              'fuelwatertanks_number' => :fuel_water_tanks_number, # 1000 L
              'freshwatertanks_number' => :fresh_water_tanks_number, # 1000 L
              'freshwatermaker_make' => :freshwatermaker, # 80 L/HR
              'antenna_characs' => :antenna, # Antena de radar Radome Digital Raymarine
              'compass_makemodel' => :compass, # OFFSHORE
              'plotter_makemodel' => :plotter, # RAYMARINE E 120
              'radiotapeplayer_makemodel' => :radiotape_player, # Sonic Hub
              'fishing_depth_sounder_makemodel' => :fishing_depth_sounder, # Sonda Lowrance HDI
              'battery_comments' => :battery, # 12v
              'radar_makemodel' => :radar, # Radome Seul
              'cd_makemodel' => :cd_player, # y lector MP3 con altavoces interiores y exteriores
              'vhf_characs' => :vhf, # Fija
              'fridge_capa' => :fridge_capacity, # 42l
              'depth_sounder_makemodel' => :depth_sounder, # LOWRANCE HDI
              'gps_makemodel' => :gps, # map 276C Garmin
              'windlass_power' => :windlass_power, # 1000 W SUBIDA / BAJADA - MANDO
              'alternator_year' => :alternator_year, # 0
              'windspeed_makemodel' => :windspeed, # RAYMARINE ST 60
              'ropecutter' => :rope_cutter, # 1
              'tv_characs' => :tv, # 3 x
              'dinghy_year' => :dinghy_year, # 0
              'dinghy_make' => :dinghy, # Yamaha 230 + Yamaha 5 HP
              'chemicalheads_number' => :chemical_heads, # 2
              'idb' => '', # 23340MSF
              'spinnaker_pole_characs' => :spinnaker_pole, # ALUMINIUM
              'regata' => :regata, # 1
              'navcenter_makemodel' => :navcenter, # BetG HERCULE 2000
              'heat_make' => :heating, # EBERPACHER
              'electronicchart_makemodel' => :electronicchart, # BetG Deckman
              'hull_painting_year' => :hull_painting_year, # 0
              'spi_characs' => :spinnaker, # ASSY
              'solarpanels_year' => :solar_panels_year, # 0
              'dinghy_engine' => :dinghy_engine, # 0
              'tv_makemodel' => :tv, # DANS CARRE
              'log_makemodel' => :log, # SPEED SOND RAYMARINE
              'inverter_make' => :inverter, # 1500 W
              'antenna_makemodel' => :antenna, # TV
              'upholstery_replacement_year' => :upholstery_replacement_year, # 0
              'launching_trailor_year' => :launching_trailor_year, # 0
              'windlass_make' => :windlass, # Double commande
              'repeater_year' => :repeater_year, # 0
              'number_people' => :number_people, # 6
              'life_raft_age' => :life_raft_age, # 2012
              'dinghy_type' => :dinghy_type, # suzuki
              'radar_characs' => :radar, # RAYMARINE
              'radardetector_year' => :radar_detector_year, # 2008
              'navcenter_characs' => :navcenter, # RAYMARINE
              'steering_wheel_characs' => :steering_wheel, # 2
              'dinghy_engine_power' => :dinghy_engine_power, # 40
              'radiotapeplayer_characs' => :radiotape_player, # SONIC HUB
              'gps_characs' => :gps, # HDS 7
              'electronicchart_characs' => :electronicchart, # lowrance HDS 7
              'depth_sounder_characs' => :depth_sounder, # HDS 7 TOUCH
              'repeater_makemodel' => :repeater, # RAYMARINE E120
              'trailor_year' => :trailor_year, # 0
              'trailor_model' => :trailor, # PAM B401 M
              'antiosmosistreatment_year' => :anti_osmosis_treatment_year, # 0
              'electric_winch_characs' => :electric_winch, # Harken X 4
              'main_sheet_traveller_characs' => :mainsheet_traveller, # HARKEN
              'mainsail_characs' => :mainsail, # HARKEN
              'battened_characs' => :battened, # Performance Mylar - Taffetas (2 ris automatiques)
              'deal_pending' => -> (boat, val) { boat.offer_status = 'under_offer' if val && val == '1'}, # 0
          )
        end

        def self.validate_param_option
          {broker_id: [:presence, /\A\d+\z/]}
        end

        def enqueue_jobs
          feed_file = "#{Rails.root}/import_data/eyb.xml"
          if @prev_import_ran_at && @prev_import_ran_at > File.mtime(feed_file) && !ENV['IGNORE_FEED_MTIME']
            log_warning 'Feed file not updated since last run. Nothing to update'
            @exit_worker = true
            return
          end

          doc = Nokogiri::XML(File.read(feed_file))

          doc.css("An_Broker[text()='#{@import.param['broker_id']}']").each do |broker|
            enqueue_job(ad: broker.parent)
          end
        end

        def process_job(job)
          doc = job[:ad]
          boat = SourceBoat.new

          doc.element_children.each do |node|
            next if node.name.start_with?('Deal_') || node.name == 'An_Broker'

            if node.name == 'URL_Photo'
              boat.images = node.element_children.map(&:text)
            else
              key = node.name.sub('An_', '').downcase
              val = node.text
              next if val.blank?

              if (attr = data_mapping[key])
                next if attr == ''
                if attr.is_a?(Proc)
                  attr.call(boat, val)
                else
                  boat.send("#{attr}=", val)
                end
              else
                if key == 'comments_en'
                  boat.description = val # Replace foreign descriptions with English one
                elsif val.length < 256 # Ignore other long values
                  boat.set_missing_attr(key, val)
                end
              end
            end
          end

          boat
        end
      end
    end
  end
end