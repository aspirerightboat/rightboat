module Rightboat
  module Imports
    module Importers
      class Boatsandoutboards < ImporterBase

        def self.data_mappings
          @data_mappings ||= SourceBoat::SPEC_ATTRS.inject({}) { |h, attr| h[attr.to_s] = attr; h }.merge(
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
              'length' => ->(boat, val) { boat.length_m = get_value_m(val) },
              'draft' => ->(boat, val) { boat.draft_m = get_value_m(val) },
              'no_of_air_chambers' => ->(boat, val) { boat.set_missing_attr(:chambers_count, val) },
              'no_of_previous_owners' => ->(boat, val) { boat.set_missing_attr(:previous_owners_count, val) },
              'width' => ->(boat, val) { boat.set_missing_attr('width', get_value_m(val)) },
              'condition' => :new_boat
          )
        end

        def host
          'www.boatsandoutboards.co.uk'
        end

        def self.params_validators
          {source_id: [:presence, /\A[A-Za-z0-9]{1,7}\z/]}
        end

        def enqueue_jobs
          url = "http://www.boatsandoutboards.co.uk/view-trader/permalink/#{@source_id}"

          begin
            while url
              log "Parsing #{url}"
              doc = get(url)
              doc.search('div.listingsv2 td .title a').each do |a|
                unless (detail_page = a['href']).blank?
                  enqueue_job(url: detail_page)
                end
              end

              next_link = doc.search('.nav a.nav_next').first
              url = next_link ? next_link['href'] : nil
            end
          rescue SocketError
            log_error 'Cannot retrieve IDs', "Verify source id parameter in #{url}"
            raise
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
              value_m = val.to_f.ft_to_m
              break
            end
          end

          value_m
        end

        def process_job(job)
          url = job[:url]
          boat = SourceBoat.new(importer: self)
          fields = {}
          boat.source_id = url[/\d+$/]
          url = advert_url(url)
          boat.source_url = url
          doc = get(url)

          doc.search('table.other_details tr').each do |tr|
            tr.search('.label').each do |key_td|
              key = key_td.text.strip.gsub(/((\s+)?:$|\.)/, '').gsub(/(\s+|\/)/, '_').downcase
              value = key_td.next.text.strip
              fields[key] =  value unless key.blank? || value.blank?
            end
          end

          doc.search('.ad-block-content ul.multi li').each do |li|
            next if li.attr('class') == 'category'
            key = li.text().gsub(/(\s+|\/)/, '_').downcase
            fields[key] = 'Yes'
          end

          boat.name = doc.search('.ad_header .title').first.text.strip rescue nil
          price_text = doc.search('.ad_header .price').first.text.strip.gsub(/[\s,]/, '') rescue nil
          boat.price = price_text[/\d+/].to_i rescue nil
          boat.vat_rate = price_text[/[^\d]+$/].strip rescue nil
          boat.location = doc.search('.ad_header .location').first.text.strip rescue nil
          boat.description = doc.search('.ad_descr').first.children.to_s rescue ''

          images = []
          doc.search('.ad_icn_photos a').map do |img|
            url = advert_url(img['data-img'])
            images << {url: url} if url
          end
          boat.images = images

          fields.each do |key, val|
            if (attr = self.class.data_mappings[key])
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
