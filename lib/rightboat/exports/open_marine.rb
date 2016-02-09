require 'builder'

module Rightboat
  module Exports
    # schema is described here: http://www.openmarine.org/schema.aspx credentials admin/admin

    class OpenMarine
      def self.export_user_boats(user)
        dir = FileUtils.mkdir_p("#{Rails.root}/public/exports").first
        file = File.open("#{dir}/#{user.slug}-#{user.broker_info.unique_hash}.xml", 'w+')
        new(user, target: file).export
      end

      def initialize(user, options = {})
        @user = user
        @x = Builder::XmlMarkup.new({target: STDOUT, indent: 1}.merge(options))
      end

      def export
        @x.instruct! :xml, version: '1.0'
        @x.open_marine(version: '1.7', 'xmlns:rb' => 'rightboat.com',
                       language: 'english', origin: 'rightboat.com',
                       date: Time.current.iso8601) {
          @x.broker(code: @user.id) { # actually here could be many broker tags but for our purpose there is always 1 broker
            @x.broker_details {
              @x.company_name @user.company_name.titleize
            }
            add_offices
            add_boats
          }
        }
      end

      def add_offices
        # head_office = Office.new(
        #     name: "#{@user.company_name} Head Office",
        #     contact_name: @user.broker_info.contact_name,
        #     # daytime_phone: 123,
        #     # evening_phone: 123,
        #     mobile: @user.phone,
        #     # fax: 123,
        #     email: @user.email,
        #     website: @user.broker_info.website,
        #     address_attributes: {
        #         line1: @user.address.line1,
        #         line2: @user.address.line2,
        #         town_city: @user.address.town_city,
        #         county: @user.address.county,
        #         country_id: @user.address.country_id,
        #         zip: @user.address.zip,
        #     }
        # )
        # offices = [head_office] + @user.offices.includes(address: :country)
        offices = @user.offices.includes(address: :country)

        @x.offices {
          offices.each do |office|
            @x.office(id: office.id) {
              @x.office_name office.name
              @x.email office.email
              @x.name {
                @x.title nil # office.title
                @x.forename office.contact_name.to_s.split(' ').first
                @x.surname office.contact_name.to_s.split(' ').last
              }
              @x.address "#{office.address.line1} #{office.address.line2} #{office.address.line3}".strip
              @x.town office.address.town_city
              @x.county office.address.county
              @x.country office.address.country.name
              @x.postcode office.address.zip
              @x.daytime_phone office.daytime_phone
              @x.evening_phone office.evening_phone
              @x.fax office.fax
              @x.mobile office.mobile
              @x.website office.website
            }
          end
        }
      end

      def add_boats
        boats = @user.boats.not_deleted.includes(:manufacturer, :model, :currency, :country, :vat_rate, :boat_images, :fuel_type, :engine_manufacturer, :drive_type)
        @x.adverts {
          boats.each do |boat|
            specs = boat.boat_specifications.specs_hash
            @x.advert(ref: boat.id, office_id: boat.office_id || 0, status: boat.offer_status.camelize) {
              @x.advert_media {
                primary = true
                boat.boat_images.not_deleted.order(:position, :id).each do |image|
                  next unless image.file.file
                  content_type = MIME::Types.type_for(image.file.file.filename).first.content_type
                  @x.media image.file.url, content_type: content_type, caption: nil, primary: primary
                  primary = false
                end
              }
              @x.advert_features {
                @x.new_or_used (boat.new_boat? ? 'new' : 'used').camelize
                @x.vessel_lying boat.location, country: boat.country.try(:iso) || Country.find_by(iso: 'GB')
                currency = boat.currency || Currency.find_by(name: 'GBP')
                @x.asking_price boat.price.to_i, poa: boat.poa, currency: currency.name, vat_included: boat.vat_rate.try(:tax_paid?)
                @x.marketing_descs {
                  @x.marketing_desc boat.description, language: 'en_GB'
                }
                @x.manufacturer boat.manufacturer.name
                @x.model boat.model.name
              }
              @x.boat_features {
                spec_item boat.name, 'name'
                spec_item boat.owners_comment, 'owners_comment'
                spec_item specs.delete(:known_defects), 'known_defects'
                spec_item specs.delete(:range), 'range'
                spec_item specs.delete(:last_serviced), 'last_serviced'
                spec_item specs.delete(:passengers), 'passenger_capacity'
                @x.dimensions {
                  spec_item specs.delete(:beam_m), 'beam', unit: 'metres'
                  spec_item specs.delete(:draft_m), 'draft', unit: 'metres'
                  spec_item boat.length_m, 'loa', unit: 'metres'
                  spec_item specs.delete(:lwl_m), 'lwl', unit: 'metres'
                  spec_item specs.delete(:air_draft), 'air_draft', unit: 'metres'
                }
                @x.build {
                  spec_item specs.delete(:designer), 'designer'
                  spec_item specs.delete(:builder), 'builder'
                  #spec_item boat.where, 'where'
                  spec_item boat.year_built, 'year'
                  spec_item specs.delete(:hull_color), 'hull_colour'
                  spec_item specs.delete(:hull_construction), 'hull_construction'
                  spec_item specs.delete(:hull_number), 'hull_number'
                  spec_item specs.delete(:hull_type), 'hull_type'
                  spec_item specs.delete(:super_structure_colour), 'super_structure_colour'
                  spec_item specs.delete(:super_structure_construction), 'super_structure_construction'
                  spec_item specs.delete(:deck_colour), 'deck_colour'
                  spec_item specs.delete(:deck_construction), 'deck_construction'
                  spec_item specs.delete(:cockpit_type), 'cockpit_type'
                  spec_item specs.delete(:control_type), 'control_type'
                  spec_item specs.delete(:flybridge), 'flybridge', with_description: true
                  spec_item specs.delete(:keel_type), 'keel_type'
                  spec_item specs.delete(:ballast), 'ballast', units: 'kg'
                  spec_item specs.delete(:displacement_kgs), 'displacement', units: 'kgs'
                }
                @x.galley {
                  spec_item specs.delete(:oven), 'oven', with_description: true
                  spec_item specs.delete(:microwave), 'microwave', with_description: true
                  spec_item specs.delete(:fridge), 'fridge', with_description: true
                  spec_item specs.delete(:freezer), 'freezer', with_description: true
                  spec_item specs.delete(:heating), 'heating', with_description: true
                  spec_item specs.delete(:air_conditioning), 'air_conditioning', with_description: true
                  # rb_spec_item specs.galley_hob, 'galley_hob', with_description: true
                  rb_spec_item specs.delete(:dishwasher), 'dishwasher', with_description: true
                  # rb_spec_item specs.delete(:sink_drainer), 'sink_drainer', with_description: true
                  # rb_spec_item specs.delete(:washer_dryer), 'washer_dryer', with_description: true
                  # rb_spec_item specs.delete(:overhead_lowlevel_courtesy_lighting), 'overhead_lowlevel_courtesy_lighting', with_description: true
                  # rb_spec_item specs.delete(:hot_cold_water_system), 'hot_cold_water_system', with_description: true
                }
                @x.engine {
                  spec_item specs.delete(:stern_thruster), 'stern_thruster', with_description: true
                  spec_item specs.delete(:bow_thruster), 'bow_thruster', with_description: true
                  spec_item boat.fuel_type.try(:name), 'fuel'
                  spec_item specs.delete(:engine_hours), 'hours'
                  spec_item specs.delete(:cruising_speed), 'cruising_speed'
                  spec_item specs.delete(:max_speed), 'max_speed'
                  spec_item specs.delete(:engine_horse_power), 'horse_power'
                  spec_item boat.engine_manufacturer.try(:name), 'engine_manufacturer'
                  spec_item specs.delete(:engine_count), 'engine_quantity'
                  spec_item specs.delete(:engine_tankage), 'tankage', unit: 'gallons/litres'
                  spec_item specs.delete(:gallons_per_hour), 'gallons_per_hour'
                  spec_item specs.delete(:litres_per_hour), 'litres_per_hour'
                  spec_item specs.delete(:engine_location), 'engine_location'
                  #spec_item boat.gearbox, 'gearbox', with_description: true
                  #spec_item boat.cylinders, 'cylinders', with_description: true
                  spec_item specs.delete(:propeller_type), 'propeller_type'
                  spec_item specs.delete(:starting_type), 'starting_type'
                  spec_item boat.drive_type.try(:name), 'drive_type'
                  spec_item specs.delete(:cooling_system), 'cooling_system', type: ''
                }
                @x.navigation {
                  spec_item specs.delete(:navigation_lights), 'navigation_lights', with_description: true
                  spec_item specs.delete(:compass), 'compass', with_description: true
                  spec_item specs.delete(:depth_instrument), 'depth_instrument', with_description: true
                  spec_item specs.delete(:wind_instrument), 'wind_instrument', with_description: true
                  spec_item specs.delete(:autopilot), 'autopilot', with_description: true
                  spec_item specs.delete(:gps), 'gps', with_description: true
                  spec_item specs.delete(:vhf), 'vhf', with_description: true
                  spec_item specs.delete(:plotter), 'plotter', with_description: true
                  spec_item specs.delete(:speed_instrument), 'speed_instrument', with_description: true
                  spec_item specs.delete(:radar), 'radar', with_description: true
                }
                @x.accommodation {
                  spec_item specs.delete(:cabins), 'cabins'
                  spec_item specs.delete(:berths), 'berths'
                  spec_item specs.delete(:toilet), 'toilet', with_description: true
                  spec_item specs.delete(:shower), 'shower', with_description: true
                  spec_item specs.delete(:bath), 'bath', with_description: true
                }
                @x.safety_equipment {
                  spec_item specs.delete(:life_raft), 'life_raft', capacity: '', with_description: true
                  spec_item specs.delete(:epirb), 'epirb', with_description: true
                  spec_item specs.delete(:bilge_pump), 'bilge_pump', with_description: true
                  spec_item specs.delete(:fire_extinguisher), 'fire_extinguisher', type: '', with_description: true
                  spec_item specs.delete(:mob_system), 'mob_system', type: '', with_description: true
                }
                @x.rig_sails {
                  spec_item specs.delete(:genoa), 'genoa', material: '', with_description: true
                  spec_item specs.delete(:spinnaker), 'spinnaker', material: '', with_description: true
                  spec_item specs.delete(:tri_sail), 'tri_sail', material: '', with_description: true
                  spec_item specs.delete(:storm_jib), 'storm_jib', material: '', with_description: true
                  spec_item specs.delete(:main_sail), 'main_sail', material: '', with_description: true
                  spec_item specs.delete(:winches), 'winches'
                }
                @x.electronics {
                  spec_item specs.delete(:battery), 'battery', with_description: true
                  spec_item specs.delete(:battery_charger), 'battery_charger', with_description: true
                  spec_item specs.delete(:generator), 'generator', with_description: true
                  spec_item specs.delete(:inverter), 'inverter', with_description: true
                }
                @x.general {
                  spec_item specs.delete(:tv), 'television', with_description: true
                  spec_item specs.delete(:cd_player), 'cd_player', with_description: true
                  spec_item specs.delete(:dvd_player), 'dvd_player', with_description: true
                  #rb_spec_item specs.delete(:surround_sound_system), 'surround_sound_system', with_description: true
                  #rb_spec_item specs.delete(:satellite_tv), 'satellite_tv', with_description: true
                  #rb_spec_item specs.delete(:satellite_phone), 'satellite_phone', with_description: true
                }
                @x.equipment {
                  spec_item specs.delete(:anchor), 'anchor', with_description: true
                  spec_item specs.delete(:spray_hood), 'spray_hood', with_description: true
                  #spec_item boat.bimini, 'bimini', with_description: true
                  spec_item specs.delete(:fenders), 'fenders', with_description: true
                  spec_item specs.delete(:shore_power), 'shorepower', with_description: true
                }
                @x.rb(:additional) {
                  # rb_spec_item specs.delete(:water_heater), 'water_heater', with_description: true
                  # rb_spec_item specs.delete(:vacuum_toilets), 'vacuum_toilets', with_description: true
                  rb_spec_item specs.delete(:holding_tanks), 'holding_tank', with_description: true
                  # rb_spec_item specs.delete(:anchor_winch), 'anchor_winch', with_description: true
                  # rb_spec_item specs.delete(:covers), 'covers', with_description: true
                  # rb_spec_item specs.delete(:bathing_platform), 'bathing_platform', with_description: true
                  # rb_spec_item specs.delete(:hydraulic_passarelle), 'hydraulic_passarelle', with_description: true
                  # rb_spec_item specs.delete(:garage), 'garage', with_description: true
                  # rb_spec_item specs.delete(:tender), 'tender', with_description: true
                  # rb_spec_item specs.delete(:stern_docking_winches), 'stern_docking_winches', with_description: true
                  # rb_spec_item specs.delete(:underwater_lighting), 'underwater_lighting', with_description: true
                  # rb_spec_item specs.delete(:teak_laid_cockpit), 'teak_laid_cockpit', with_description: true
                  # rb_spec_item specs.delete(:teak_laid_flybridge), 'teak_laid_flybridge', with_description: true
                  # rb_spec_item specs.delete(:teak_laid_side_decks), 'teak_laid_side_decks', with_description: true
                  # rb_spec_item specs.delete(:wetbar), 'wetbar', with_description: true
                  # rb_spec_item specs.delete(:sunbather), 'sunbather', with_description: true
                  # rb_spec_item specs.delete(:stainless_steel_sliding_door_to_aft_cockpit), 'stainless_steel_sliding_door_to_aft_cockpit', with_description: true
                  # rb_spec_item specs.delete(:hydraulic_trim_tabs), 'hydraulic_trim_tabs', with_description: true
                  # rb_spec_item specs.delete(:hot_cold_swimming_shower), 'hot_cold_swimming_shower', with_description: true
                  # rb_spec_item specs.delete(:freshwater_capacity), 'freshwater_capacity', :units => specs.freshwater_capacity_units
                  specs.each { |name, value| rb_spec_item value, name }
                }
              }
            }
          end
        }
      end

      def spec_item(spec_value, spec_name, options = {})
        if spec_value.present?
          attributes = {name: spec_name}

          if options.delete(:with_description)
            attributes['rb:description'] = spec_value if spec_value !~ /true|1|yes/i
            spec_value = 'Yes'
          end

          if options.delete(:rb_item)
            @x.rb :item, spec_value, attributes.merge!(options)
          else
            @x.item spec_value, attributes.merge!(options)
          end
        end
      end

      def rb_spec_item(spec_value, spec_name, options = {})
        spec_item(spec_value, spec_name, options.merge!(rb_item: true))
      end
    end

  end
end
