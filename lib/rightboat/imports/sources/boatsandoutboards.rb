# encoding: utf-8

module Rightboat
  module Imports
    module Sources
      class Boatsandoutboards < Base
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
          { source_id: [:presence, /^[A-Za-z0-9]{1,7}$/] }
        end

        def advert_url(url)
          return unless url
          uri = URI(url)
          uri.host ||= 'www.boatsandoutboards.co.uk'
          uri.scheme ||= 'http'
          uri.to_s
        end

        def enqueue_jobs
          url = "http://www.boatsandoutboards.co.uk/view-trader/permalink/#{@source_id}"

          begin
            while (url)
              puts "parsing #{url}"
              doc = get(url)
              doc.search("div.listingsv2 td .title a").each do |a|
                unless (detail_url = a['href']).blank?
                  job = { url: detail_url }
                  enqueue_job(job)
                end
              end

              next_link = doc.search('.nav a.nav_next').first
              url = next_link ? next_link['href'] : nil
            end
          rescue SocketError => se
            puts "Inable to retrieve IDs - verify source id parameter in " + url
            exit 1
          end
        end

        def self.get_value_m(values)
          value_m = nil

          values.to_s.split('/').each do |val|
            val = val.strip
            if val =~ /m$/
              value_m = val.to_f.round(2)
              break
            elsif val =~ /ft$/
              value_m = val.to_f * 0.3048
              break
            end
          end

          value_m
        end

        def process_job(job)
          url = job[:url]
          boat = SourceBoat.new
          fields = {}
          boat.source_id = url[/\d+$/].to_s
          url = advert_url(url)
          boat.source_url = url
          doc = get(url)

          doc.search("table.other_details tr").each do |tr|
            tr.search(".label").each do |key_td|
              key = key_td.text.strip.gsub(/((\s+)?:$|\.)/, '').gsub(/(\s+|\/)/, '_').downcase
              value = key_td.next().text.strip
              fields[key] =  value unless key.blank? || value.blank?
            end
          end

          doc.search('.ad-block-content ul.multi li').each do |li|
            next if li.attr('class') == 'category'
            key = li.text().gsub(/(\s+|\/)/, '_').downcase
            fields[key] = 'Yes'
          end

          boat.boat_type = fields['type']
          price_text = doc.search('.ad_header .price').first.text.strip.gsub(/[\s,]/, '') rescue nil
          boat.price = price_text[/\d+/].to_i rescue nil
          boat.vat_rate = price_text[/[^\d]+$/].strip rescue nil
          boat.location = doc.search('.ad_header .location').first.text.strip rescue nil
          boat.description = doc.search('.ad_descr').first.children.to_s rescue ''

          boat.images = doc.search('.ad_icn_photos a').map do |img_link|
            advert_url(img_link['data-img'])
          end.reject(&:blank?)

          fields.each do |key, val|
            if (attr = DATA_MAPPINGS[key])
              if attr.is_a?(Proc)
                attr.call(boat, val)
              else
                boat.send("#{attr}=", val)
              end
            else
              boat.set_missing_attr(key, val)
            end
          end

          boat
        end
      end
    end
  end
end
