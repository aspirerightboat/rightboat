# encoding: utf-8

module Rightboat
  module Imports
    module Sources
      class Boatshop24 < Base
        DATA_MAPPINGS = SourceBoat::SPEC_ATTRS.inject({}) {|h, attr| h[attr.to_s] = attr; h}.merge(
          'currency' => :currency,
          'manufacturer' => :manufacturer,
          'year_built' => :year_built,
          'model' => :model,
          'hull_type' => :hull_type,
          'type' => :boat_type,
          'drive_type' => :drive_type,
          'builder' => :builder,
          'engine_manufacturer' => :engine_manufacturer,
          'engine_hours' => :engine_hours,
          'mooring_country' => :country,
          'weight_dry' => :dry_weight,
          'no_of_engines' => :engine_count,
          'fuel' => :fuel_type,
          'material_hull' => :hull_material,
          'hp' => :engine_horse_power,
          'length' => Proc.new { |boat, val| boat.length_m = get_value_m(val) },
          'draft' => Proc.new { |boat, val| boat.draft_m = get_value_m(val) },
          'no_of_air_chambers' => Proc.new { |boat, val| boat.set_missing_attr(:chambers_count, val) },
          'no_of_previous_owners' => Proc.new { |boat, val| boat.set_missing_attr(:previous_owners_count, val) },
          'width' => Proc.new { |boat, val| boat.set_missing_attr('width', get_value_m(val)) },
          'condition' => Proc.new do |boat, val|
            if val =~ /new/i
              boat.new_boat = true
            elsif val =~ /used/i
              boat.new_boat = false
            end
          end
        )

        def self.validate_param_option
          { offices: [], source_id: [:presence, /^[A-Za-z0-9]{1,7}$/] }
        end

        def advert_url(url)
          "http://www.boatshop24.co.uk/#{url}"
        end

        def pics_url id
          "http://search.boatshop24.co.uk/brokersfullspec.asp?btsrefno=#{id}"
        end

        def enqueue_jobs
          url = "http://search.boatshop24.co.uk/externalbrokerlist.asp?brokercode=#{@source_id}"

          begin
            while url
              log "Parsing #{url}"
              doc = get(url)
              doc.search('.latest_ads .desc-top .title a').each do |a|
                unless (detail_page = a['href']).blank?
                  enqueue_job(url: detail_page)
                end
              end

              next_link = doc.search('.nav a.nav_next').first
              url = next_link ? next_link['href'] : nil
            end
          rescue SocketError => e
            log_error "#{e.message} Error: Cannot retrieve IDs - verify source id parameter in #{url}", 'Cannot retrieve IDs'
            exit 1
          end
        end

        def process_job(job=nil)
          #url = job[:url]
          url = '/cabin-cruiser/viking-20/76336'
          boat = SourceBoat.new
          fields = {}
          boat.source_id = url[/\d+$/].to_s
          url = advert_url(url)
          boat.source_url = url

          doc = get(url)
          doc.save_as 'log.html'
          return

          boat.manufacturer, boat.model = doc.css("#rightColumnContainer h2").text.split(/\s+/,2)
          price = doc.css("#priceArea h4").text
          if doc.to_s.match(/UNDER OFFER/)
            boat.under_offer = true
          end
          puts "manufacturer: #{boat.manufacturer}"
          puts "model: #{boat.model}"
          if price
            boat.price = price.gsub(/[^0-9\.]+/,'')
          end
          boat.description = doc.css("#description p").text
          puts "Description: #{boat.description}"
          if doc.to_s.match(/Ex Tax/)
            boat.vat_rate = "Ex VAT"
          end
          doc.to_s.scan(/<th>(.*?)<\/th>\s*<td>(.*?)<\/td>/mi).each do |pair|
            label, data = pair
            unless label.blank?
              puts pair.inspect
              case label
                when "Draft (Feet)"
                  boat.draft_ft, boat.draft_in = data.match(/(\d+)'\s*(\d+)"/).to_a[1..2]
                when "Draft (Metres)"
                  boat.draft_m = data.to_f.to_s
                when "LOA (Feet)"
                  length_ft, length_in = data.match(/(\d+)'\s*(\d+)"/).to_a[1..2]
                  boat.length_ft = length_ft.to_f + (length_in / 12.0)
                when "LOA (Metres)"
                  boat.length_m = data.to_f.to_s
                when "Beam (Metres)"
                  boat.beam_m = data.to_f.to_s
                when "Year Built"
                  boat.year_built = data.to_i.to_s
                when "Engine Power"
                  boat.engine_horse_power = data.to_i.to_s
                when "Max Speed"
                  boat.max_speed = data.to_i.to_s
                when "Fuel"
                  boat.fuel_type = data.to_s
                when "Berths"
                  boat.berths_guests = data.to_s.to_i
                when "Cabins"
                  boat.cabins_guest = data.to_s.to_i
                when "Engine Manufacturer"
                  boat.engine_manufacturer = data.to_s
                when "Hull Type"
                  boat.hull_type = data.to_s
                when "Hull Construction"
                  boat.hull_construction = data.to_s
              end
            end
          end

          begin
            doc = Nokogiri::HTML(open(pics_url(id)))
            doc.css("#thumbnail_images a").each do |img_link|
              url = URI.parse(URI.encode img_link['href'])
              url.host ||= "www.boatshop24.co.uk"
              url.scheme ||= 'http'
              img_src = url.to_s.gsub(/\&width\=\d+$/, '')
              boat.images << img_src
            end
          rescue OpenURI::HTTPError => e
            puts "#{pics_url(id)} #{e.message}"
          end

          boat
        end
      end
    end
  end
end
