# encoding: utf-8

module Rightboat
  module Imports
    module Importers
      class Yatco < ImporterBase
        DATA_MAPPINGS = SourceBoat::SPEC_ATTRS.inject({}) {|h, attr| h[attr.to_s] = attr; h}.merge(
          'vessel_id' => :source_id,
          'vessel_type' => :boat_type,
          'boatname' => :name,
          'main_category' => :category,
          'asking_price' => :price,
          'currency' => :currency,
          'cruise_speed_knots' => :cruising_speed,
          'location_country' => :country,
          'location_city' => :location,
          'description_short_description' => :short_description,
          'loa_meters' => :length_m,
          'beam_meters' => :beam_m,
          'lwl_meters' => :lwl_m,
          'min_draft_meters' => :draft_m,
          'model' => :model,
          'builder' => :manufacturer,
          'engine_manufacturer' => :engine_manufacturer,
          'engine_model' => :engine_model,
          'engine_count' => :engine_count,
          'engine_hours1' => :engine_hours,
          'engine_hours3' => :engine_hours3,
          'engine_year1' => :engine_year,
          'engine_year3' => :engine_year3,
          'engine_horse_power1' => :engine_horse_power,
          'engine_horse_power3' => :engine_horse_power3,
          'engine_date_hours_registered1' => :engine_date_hours_registered1,
          'fuel_type' => :fuel_type,
          'fuel_capacity_ltr' => :fuel_tanks_capacity,
          'holding_tank_ltr' => :holding_tanks_capacity,
          'hull_id' => :hull_id,
          'num_berths' => :berths_count,
          'num_heads' => :heads_count,
          'rpm_cruise_speed' => :cruise_speed_rpm,
          'rpm_max_speed' => :max_speed_rpm,
          'tax_paid' => :vat_rate,
          'condition' => :new_boat,
          'propulsion_type' => :drive_type,
          'year_built' => :year_built,
          'water_capacity_ltr' => :water_tanks_capacity,
          'weight_kilos' => :dry_weight
        )

        def self.params_validators
          {api_key: [:presence, /[a-z\d\-]+/], company_id: [:presence, /\A\d+\z/]}
        end

        def enqueue_jobs
          doc = get("http://data.yatco.com/dataservice/#{@import.param['api_key']}/vessellist")

          doc.search("CompanyID[text()='#{@import.param['company_id']}']").each do |company|
            job = { vessel_id: company.parent.children.search('VesselID').first.text }
            enqueue_job(job)
          end
        end

        def process_job(job)
          doc = get("http://data.yatco.com/dataservice/#{@import.param['api_key']}/vesseldetails/#{job[:vessel_id]}")
          boat = SourceBoat.new
          boat.office = { address_attributes: {} }

          doc.search('Vessel').first.children.each do |node|
            key = node.name.underscore.gsub('engine_engine', 'engine').gsub('hull_hull', 'hull')
            next if key =~ /(company|feet|formatted|vessel_sections)/i
            val = node.children.text
            next if val.blank?

            if key == 'gallery'
              boat.images = node.children.map { |g| g.search('url').first.text }.reject(&:blank?).map { |url| {url: url} }
            else
              if (attr = DATA_MAPPINGS[key])
                if attr.is_a?(Proc)
                  attr.call(boat, val)
                else
                  boat.send("#{attr}=", val)
                end
              else
                case
                when key == 'model_year' && boat.model.blank? then boat.model = val
                when key =~ /description/i && boat.description.blank? then boat.description = val
                when key =~ /location_(region_name|state)/
                  boat.location = val if boat.location.blank?
                when key == 'sales_person' then boat.office[:name] = boat.office[:contact_name] = val
                when key == 'sales_person_fax' then boat.office[:fax] = val
                when key == 'sales_person_email' then boat.office[:email] = val
                when key == 'sales_person_phone' then boat.office[:daytime_phone] = val
                when key == 'sales_person_cell_phone' then boat.office[:mobile] = val
                when key =~ /^sales_p(?:er|re)son_address1$/ then boat.office[:address_attributes][:line1] = val # "preson" misspelled in xml
                when key =~ /^sales_p(?:er|re)son_city$/ then boat.office[:address_attributes][:town_city] = val # "preson" misspelled in xml
                when key =~ /^sales_p(?:er|re)son_state$/ then boat.office[:address_attributes][:state] = val # "preson" misspelled in xml
                when key =~ /^sales_p(?:er|re)son_postal_code$/ then boat.office[:address_attributes][:zip] = val # "preson" misspelled in xml
                when key == 'sales_person_id'
                when val.length < 256 then boat.set_missing_attr(key, val) # Ignore other long values
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