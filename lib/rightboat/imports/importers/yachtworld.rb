module Rightboat
  module Imports
    module Importers
      class Yachtworld < ImporterBase
        def data_mapping
          @data_mapping ||= {
              'Boat Name' => :name,
              'Hull Material' => :hull_material,
              'Year' => :year_built,
              'Current Price' => Proc.new { |boat, data|
                if (m = data.match(/^(?:(?<currency>[A-Z$£]{1,3})\s+)?(?<price>[\d,]+)\s*(?<vat>.*)$/))
                  boat.currency = ('USD' if m[:currency] == 'US$') || m[:currency] || Currency.default
                  boat.price = m[:price].gsub(',', '') if m[:price]
                  boat.vat_rate = m[:vat] if m[:vat]
                end
              },
              'Engine Brand' => :engine_manufacturer,
              'Engine Model' => :engine_model,
              'Engine Type' => :engine_type,
              'Propeller' => :propeller,
              'Fuel Type' => :fuel_type,
              'Engine/Fuel Type' => -> (_, _) {}, # nothing. parsed from summary table
              'LOA' => -> (_, _) {}, # nothing. parsed from summary table
              'LWL' => -> (boat, data) { read_spec_len(boat, data, :lwl_m) },
              'Draft' => -> (boat, data) { read_spec_len(boat, data, :draft_m) },
              'Beam' => -> (boat, data) { read_spec_len(boat, data, :beam_m) },
              'Minimum Draft' => :draft_m,
              'Maximum Draft' => :draft_m,
              'Maximum Speed' => :max_speed_knots,
              'Cruising Speed' => :cruising_speed,
              'Engine(s) Total Power' => :engine_horse_power,
              'Total Power' => :engine_horse_power,
              'Headroom' => :head_room,
              'Number of heads' => :heads_count,
              'Number of single berths' => :single_berths_count,
              'Number of double berths' => :double_berths_count,
              'Year Built' => Proc.new { |boat, data| boat.year_built = data },
              'Engine Hours' => :engine_hours,
              'Displacement' => :displacement_kgs,
              'Ballast' => :ballast_kgs,
              'Electrical Circuit' => :electrical_circuit,
              'VehicleRemarketingEngine' => Proc.new { |boat, _|
                boat.engine_count = boat.engine_count ? boat.engine_count + 1 : 1
              },
              'Drive Type' => :drive_type,
              'Manufacturer' => :manufacturer,
              'Model' => :model,
              'Country of built' => :country_built,
              'Net' => :displacement_net,
              'Gross' => :displacement_gross,
              'Hull' => -> (_, _) {}, # nothing. parsed from summary table
              'Deck' => :deck_material,
              'No. of guest cabins' => :cabins_count,
              'No. of guest berths' => :berths_count,
              'No. of WC' => :bathrooms,
              'Dinette Sleeps' => :dinette_sleeps,
              'No. of crew cabins' => :crew_cabins_count,
              'No. of crew berths' => :crew_berths_count,
              # 'Cruising Speed' => :cruising_speed,
              'Max Speed' => :max_speed_knots,
              'Engine(s) Manufacturer' => :engine_manufacturer,
              'Engine(s) Model/ HP' => :engine_model,
              'Type of drive' => :drive_type,
              'Type of fuel' => :fuel_type,
              'Bow thruster' => :bow_thruster,
              'Engine hours' => :engine_hours,
              'Generator Manufacturer' => :generator,
              'KW' => :generator_kw,
              'Fuel tank' => :fuel_tanks,
              'Fuel Tanks' => :fuel_tanks,
              'Fresh water tank' => :fresh_water_tanks,
              'Fresh Water Tanks' => :fresh_water_tanks,
              'Radar' => :radar,
              'Autopilot' => :autopilot,
              'Echosounder' => :echosounder,
              'GPS/ Plotter' => :gps,
              'VHF with DSC/ GMDSS' => :vhf,
              'Steering system' => :steering_system,
              'Type' => :air_conditioning,
              'Compartments' => :compartments,
              'Electrical system' => :electrical_circuit,
              'Desalinator' => :desalinator,
              'Dinghy/ outboard' => :dinghy,
              'EPIRB' => :epirb,
              'Fire extinguishers auto' => :fire_extinguisher,
              'Genoa' => :genoa,
              'Genoa furling type' => :genoa_furling,
              'Jib' => :jib,
              'Jib furling type' => :jib_furling,
              'Main Sail' => :mainsail,
              'Main Sail furling system' => :mainsail_furling,
              'Main Sail Fully battened' => :mainsail_battened,
              'Spinnaker' => :spinnaker,
              'Masts' => :masts,
              'Flag' => :country_built,
              'Flag of Registry' => :country_built,
              'VAT' => :vat_rate,
              'Length on Deck' => :length_on_deck,
              'Builder' => :builder,
              'Engine Power' => :engine_horse_power,
              'Economy Speed' => :economy_speed,
              'Stern thruster' => :stern_thruster,
              'Trim Tabs (Flaps)' => :trim_tabs,
              'Shore power connection' => :shorepower,
              'Shore inverter' => :shore_inverter,
              'Fire extinguishers portable' => :fire_extinguisher,
              'Location' => :engine_location,
              'Speed log' => :speed_log,
              'Wind & speed direction' => :wind_speed_dir,
              'Steering indicator' => :steering_indicator,
              'Dual station navigation' => :dual_station_navigation,
              'Magnetic compass' => :magnetic_compass,
              'Searchlight' => :searchlight,
              'Bilge Pumps' => :bilge_pump,
              'License' => :license,
              'Date of Refit' => :date_of_refit,
              'Wheel steering' => :wheel_steering,
              'Holding Tanks' => :holding_tanks,
              'Designer' => :designer,
              'Keel' => :keel,
              'Hull Shape' => :hull_shape,
              'Dry Weight' => :dry_weight,
              'Bow sprit' => :bow_sprit,
              'Warranty' => :warranty,
              'Deadrise' => :deadrise,
              'Number of cabins' => :cabins_count,
              'Total Liferaft Capacity' => :life_raft_capacity,
              'Bridge Clearance' => :bridge_clearance,
              'Number of twin berths' => :twin_berths_count,
              'Length of Deck' => :length_on_deck,
              'Number of bathrooms' => :bathrooms,
              'Max Load Capacity' => :max_load_capacity,
              'Seating Capacity' => :seating_capacity,
              'Range' => :range,
              'Freeboard' => :freeboard
          }
        end

        def self.params_validators
          {homepage_url: :presence}
        end

        def enqueue_jobs
          url = @homepage_url
          while url
            doc = get(url)

            rows = doc.root.css('table[summary=search_results] tr')
            break if rows.blank?
            rows.shift # remove header row

            rows.each do |row|
              tds = row.element_children
              location = tds[9].text
              next if location == 'Sold'

              job = {}
              job[:length_m] = read_length(tds[3].text)
              if location == 'Sale Pending'
                job[:offer_status] = 'under_offer'
              else
                job[:location] = location
              end
              job[:codes] = fix_whitespace(tds[8].text)
              job[:source_url] = doc.uri.merge(tds[4].at_css('a')['href']).to_s

              enqueue_job(job)
            end
            next_link = doc.root.at_css('form[name=search_results] .feature a:contains("Next")')
            url = (doc.uri.merge(next_link[:href]) if next_link.present?)
          end
        end

        private

        def process_job(job)
          source_url = job[:source_url]

          doc = get(source_url)

          boat = SourceBoat.new(source_url: doc.uri.to_s, importer: self)
          boat.source_id = url_param(source_url, 'boat_id')
          boat.length_m = job[:length_m]
          process_codes(boat, job[:codes])
          boat.location = job[:location]
          boat.offer_status = job[:offer_status] if job[:offer_status]

          desc_td = doc.root.at_css('tr[align=left] td')
          description = prepare_description(desc_td)

          if full_spec_link = doc.link_with(href: /pl_boat_full_detail/)
            full_spec_uri = doc.uri.merge(full_spec_link.uri)
            doc = get(full_spec_uri)

            h3 = doc.root.at_css('h3')
            h3_manufacturer_model = h3.text.gsub(/^\s*\d+.\s*/, '')
            get_attrs(boat, h3)

            details1 = doc.root.at_css('h2:contains("Additional Specs, Equipment")').ancestors('div').first
            details1.css('h2').remove
            section = nil
            details1.traverse do |node|
              if node.text?
                str = fix_whitespace(node.text)
                next if str.blank?

                if node.parent.name == 'strong'
                  section = str
                elsif str[':']
                  attr, data = str.split(/\s*:\s/)
                  assign_boat_attr(boat, attr, data)
                elsif str.present? && section == 'Boat Name'
                  boat.name = str
                end
              end
            end

            details2_b = doc.root.at_css('b:contains("Yacht\'s Descriptions")')
            details2 = (details2_b.ancestors('div').first if details2_b)
            if details2_b
              section = nil
              attr = nil
              details2.css('td').each do |td|
                if td[:class] == 'sectHead'
                  section = fix_whitespace(td.text)
                elsif td[:width] == '25%'
                  str = fix_whitespace(td.text)
                  if str.end_with?(':')
                    attr = str.chomp(':')
                    attr = 'Generator Manufacturer' if section == 'Generators' && attr == 'Manufacturer'
                  else
                    assign_boat_attr(boat, attr, str)
                  end
                end
              end
            end

            cur_details = details2 || details1
            while (cur_details = cur_details.next)
              next if cur_details.name != 'div'
              next if !cur_details.at_css('b')
              next if cur_details.at_css('b:contains("Disclaimer")')
              description << prepare_description(cur_details)
            end

            if boat.manufacturer && !boat.model && h3_manufacturer_model[boat.manufacturer]
              boat.model = h3_manufacturer_model.sub(boat.manufacturer, '').strip
            end

            boat.images = doc.root.css('img[src^="http://newimages.yachtworld.com"]').map do |n|
              url = n[:src].sub(/\?.*/, '')
              {url: url}
            end
          else
            h3 = doc.root.at_css('h3')
            h3_manufacturer_model = h3.text.gsub(/^\s*\d+.\s*/, '')
            get_attrs(boat, h3)

            if gallery_link = doc.link_with(href: /photo_gallery/)
              gallery_uri = doc.uri.merge(gallery_link.uri)
              doc = get(gallery_uri)
              boat.images = doc.root.css('img[src^="http://newimages.yachtworld.com"]').map do |n|
                url = n[:src].sub(/\?.*/, '')
                {url: url}
              end
            end
          end

          boat.description = description
          boat.country = boat.location.split(', ').last unless boat.country
          boat.manufacturer_model = h3_manufacturer_model if !boat.manufacturer && !boat.model
          boat
        end

        def get_attrs(boat, node)
          node.parent.css('li').each do |li|
            text = li.text
            if text =~ /located in/i
              boat.location = text.gsub(/located in/i, '').strip
              boat.country = 'United States of America' if text =~ /\(US\)/
            else
              attr, data = fix_whitespace(text).split(/\s*:\s*/)
              assign_boat_attr(boat, attr, data)
            end
          end
        end

        def process_codes(boat, codes)
          codes = codes.split(' ')
          boat.boat_type = case codes[0] when 'P' then 'Power' when 'S' then 'Sail' end
          boat.new_boat = case codes[1] when 'N' then true when 'U' then false end
          boat.engine_count = case codes[2] when 'S' then 1 when 'T' then 2 end
          boat.fuel_type = case codes[3] when 'D' then 'Diesel' when 'G' then 'Gas/Petrol' end
          boat.hull_material = case codes.last # sometimes there are no fourth code, eg.: P U O   FG
                               when 'W' then 'Wood'
                               when 'ST' then 'Steel'
                               when 'AL' then 'Aluminum'
                               when 'FG' then 'Fiberglass'
                               when 'CP' then 'Composite'
                               when 'FC' then 'Ferro-Cement'
                               end
        end

        def read_length(str)
          if !(m = str.match(/^(\d+)'\D(?:(\d+)\D"\D)?$/)).nil? && m.length > 1
            (m[1].to_f.ft_to_m + m[2].to_f.inch_to_m).round(2)
          elsif !(m = str.match(/([0-9]*\.[0-9]+|[0-9]+)(\s+)?m/)).nil? && m.length > 0
            m[1]
          end
        end

        def read_spec_len(boat, data, attr)
          case
          when (m = data.match(/^([\d.]+) ?m/)) then boat.send "#{attr}=", m[1]
          when (m = data.match(/^(\d+) ft (\d+) in/)) then boat.send "#{attr}=", m[1].to_f.ft_to_m + m[2].to_f.inch_to_m
          end
        end

        def fix_whitespace(str)
          str.squeeze_whitespaces!.strip!
        end

        def assign_boat_attr(boat, attr, data)
          return if data.blank? || data == 'n/a' || data == 'No'
          handler = data_mapping[attr]
          if !handler
            boat.set_missing_attr(attr, data)
          elsif handler.is_a?(Symbol)
            boat.send "#{handler}=", data
          elsif handler.is_a?(Proc)
            handler.call(boat, data)
          end
        end

        def prepare_description(parent_node)
          parent_node.css('strong').each do |node|
            if node.text =~ /Safeguarding|Surveyors|Transportation/
              node.ancestors('p').first.try(:remove)
            end
          end
          parent_node.inner_html
        end

      end
    end
  end
end
