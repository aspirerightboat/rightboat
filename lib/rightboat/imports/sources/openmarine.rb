module Rightboat
  module Imports
    module Sources

      # example feeds:
      # http://www.idealboat.com/theyachtmarket_feed.php
      # http://boatconnection.rightboatexpert.com/exports/c6c433b91c3666fe236a138e6d8d102680d3f1c7.xml
      # http://broadland.rightboatexpert.com/exports/c716c934db37ba58e7fa5fde3a3f83840973c42d.xml
      # https://go.openbms.nl/export/12/?b=20&u=uweycrtby&p=gwtithoicp
      # http://moorebrokerage.net/mib_om_cdata.xml
      # http://morganmarine.com/portals/portals.xml
      # http://riginosyachts.com/wp-content/uploads/Riginos.xml
      # http://81.143.47.18/boat/boats-xml/p/2/b/6/k/b987de2d33b17e6ca8aa874d58e51a6c/pk/c93422dd21571cc120a928c6ab047768
      # http://sekw.ybroker.co.uk/advert_feed.xml
      # http://www.carineyachts.com/xml_tmp_third/right-boat_103313987f94d4793d6acf8cb15c2db1.xml
      # http://www.doevemakelaar.nl/en/?option=com_sdships&task=xmlfeed&format=raw&langid=2
      # http://www.ibcmallorca.com/feeds/openmarine.xml
      # http://www.macasailor.com/openmarine.asp
      # http://www.nya.co.uk/boatsxml.php

      class Openmarine < Base
        include ActionView::Helpers::TextHelper # for simple_format

        DATA_MAPPINGS = SourceBoat::SPEC_ATTRS.inject({}) {|h, attr| h[attr.to_s] = attr; h}.merge(
            'name' => :name,
            'boat_name' => :name,
            'url' => :source_url,
            'owners_comment' => :owners_comment,
            'drive_type' => :drive_type,
            'passenger_capacity' => :passengers,
            'beam' => :beam_m, #Proc.new { |boat, item| boat.beam_m = unit_processor.call(item)},
            'draft' => :draft_m, # Proc.new { |boat, item| boat.draft_m = unit_processor.call(item)},
            'loa' => :length_m, # Proc.new { |boat, item| boat.length_m = unit_processor.call(item)},
            'lwl' => :lwl_m, #Proc.new { |boat, item| boat.lwl_m = unit_processor.call(item)},
            'displacement' => :displacement_kgs, #Proc.new { |boat, item| boat.displacement_kgs = unit_processor.call(item)},
            'year' => :year_built,
            'hull_colour' => :hull_color,
            'fuel' => :fuel_type,
            'hours' => :engine_hours,
            'horse_power' => :engine_horse_power,
            'engine_manufacturer' => :engine_manufacturer,
            'engine_quantity' => :engine_count,
            'Bimini' => :bimini
        )

        def self.validate_param_option
          { url: :presence, broker_id: [:presence, /^all|\d+$/]}
        end

        def enqueue_jobs
          log 'Loading XML file'
          doc = get(@url)

          log 'Scraping'
          broker_nodes = doc.xml.root.element_children
          broker_nodes.select { |node| @broker_id == node['code'] } if @broker_id != 'all'

          broker_nodes.each do |broker_node|
            log 'Scraping broker info'
            inner_nodes = broker_node.element_children.index_by(&:name)

            office_info_by_id = inner_nodes['offices'].element_children.each_with_object({}) do |office_node, h|
              nodes = office_node.element_children.index_by(&:name)
              country_name = (nodes['country'] || nodes['counrty']).text # counrty misspelling is here: http://81.143.47.18/boat/boats-xml/p/2/b/6/k/b987de2d33b17e6ca8aa874d58e51a6c/pk/c93422dd21571cc120a928c6ab047768
              country = country_name == 'United States' ? Country.find_by(iso: 'US') : Country.query_with_aliases(country_name).first
              h[office_node['id']] = {
                  name: nodes['office_name'].text,
                  contact_name: nodes['name'].element_children.map { |node| node.text }.join(' ').strip,
                  email: nodes['email'].text,
                  daytime_phone: nodes['daytime_phone'].text,
                  evening_phone: nodes['evening_phone'].text,
                  fax: nodes['fax'].text,
                  mobile: nodes['mobile'].text,
                  website: nodes['website'].text,
                  address_attributes: {
                      line1: nodes['address'].text,
                      town_city: nodes['town'].text,
                      county: nodes['county'].text,
                      country_id: country.id,
                      zip: nodes['postcode'].text,
                  }
              }
            end

            advert_nodes = inner_nodes['adverts'].element_children
            log "Found #{advert_nodes.size} boats"
            advert_nodes.each do |advert_node|
              office = office_info_by_id[advert_node['office_id']]
              enqueue_job(advert_node: advert_node, office: office)
            end
          end
        end

        def process_job(job)
          advert_node = job[:advert_node]
          if advert_node['status'] =~ /sold/i
            log 'Boat Sold'
            return
          end

          boat = SourceBoat.new
          boat.office = job[:office]
          boat.source_id = advert_node['ref']

          inner_nodes = advert_node.element_children.index_by(&:name)
          handle_advert_media(boat, inner_nodes['advert_media'])
          handle_advert_features(boat, inner_nodes['advert_features'])
          handle_boat_features(boat, inner_nodes['boat_features'])

          boat
        end

        def handle_advert_media(boat, advert_media)
          media_nodes = advert_media.element_children
          media_nodes.select { |node| !node['type'].start_with?('video') } # ignore "video/youtube" so far; there could be also "application/octet-stream" pointing to jpg

          if (primary_media = media_nodes.find { |n| prim = n['primary']; prim && prim =~ /true|1|yes/i }) # some sources has primary media not as first child, eg.: http://www.nya.co.uk/boatsxml.php
            media_nodes.unshift(media_nodes.delete(primary_media)) if media_nodes.index(primary_media) > 0
          end

          image_urls = media_nodes.map(&:text)
          boat.images = image_urls.map do |url|
            url = URI.encode(url)
            url = url.gsub('[', '%5B').gsub(']', '%5D') if url =~ /[\[\]]/
            url = URI.parse(@url).merge(url).to_s if !url.start_with?('http:')
            url
          end
        end

        def handle_advert_features(boat, advert_features)
          feature_nodes = advert_features.element_children.index_by(&:name)
          boat.manufacturer = feature_nodes['manufacturer'].text
          boat.model = feature_nodes['model'].text
          asking_price = feature_nodes['asking_price']
          boat.price = asking_price.text
          boat.currency = asking_price['currency']
          boat.poa = boat.price.blank? || boat.price.to_i == 0 ? true : read_poa(asking_price['poa'])
          if (vat_rate = asking_price['vat_included'])
            boat.vat_rate = read_vat_rate(vat_rate)
          end
          boat.description = feature_nodes['marketing_descs'].element_children.map do |node|
            lang = node['language']
            if !lang || lang =~ /\Aen/i || lang == 'ISO-8859-1'
              str = node.inner_html.gsub('&nbsp;', ' ').strip
              str = simple_format(str) if !str['<']
              str
            end
          end.join("\n\n").strip
          if feature_nodes['other']
            boat.source_url = feature_nodes['other'].element_children.find { |n| n['name'] == 'external_url' }.try(:text)
          end
          if feature_nodes['boat_type']
            boat.boat_type = feature_nodes['boat_type'].text
          end
          if feature_nodes['boat_category']
            boat.category = feature_nodes['boat_category'].text
          end
          if (location_el = feature_nodes['vessel_lying'])
            boat.location = location_el.text
            boat.country = location_el['country']
          end
          boat.new_boat = read_new_or_used(feature_nodes['new_or_used'].text)
        end

        def handle_boat_features(boat, boat_features)
          (boat_features.css('item') + boat_features.css('rb:item')).each do |item|
            attr = DATA_MAPPINGS[item['name']]

            value = item.text.strip
            if item['rb:description'].present?
              value = item['rb:description'].strip if value =~ /true/i
            end
            if (unit = (item['unit'] || item['units']))
              value = convert_unit(value, unit)
            end

            if !attr
              boat.set_missing_attr(item['name'], value)
            elsif attr.is_a?(Proc)
              attr.call(boat, item)
            else
              boat.send("#{attr}=", value)
            end
          end
        end

        def read_poa(str)
          return if str.blank?
          case
          when str =~ /true|1|yes/i then true
          when str =~ /false|0|no/i then false
          else log "Unexpected poa: #{str}"; nil
          end
        end

        def read_vat_rate(str)
          return if str.blank?
          case
          when str =~ /true|inc vat|1/i then 'Inc VAT'
          when str =~ /false|ex vat|0/i then 'Ex VAT'
          else log "Unexpected vat_rate: #{str}"; nil
          end
        end

        def read_new_or_used(str)
          return if str.blank?
          case
          when str =~ /new|N/i then 'new'
          when str =~ /used|U/i then 'used'
          else log "Unexpected new_or_used: #{str}"; nil
          end
        end
      end

    end
  end
end
