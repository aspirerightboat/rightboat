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
          {url: :presence, broker_id: [:presence, /\A(first|\d+)\z/]}
        end

        def enqueue_jobs
          log 'Loading XML file'
          doc = get(@import.param[:url])

          log 'Scraping'
          broker_nodes = doc.xml.root.element_children
          broker_node = @broker_id == 'first' ? broker_nodes[0] : broker_nodes.find { |node| @broker_id == node['code'] }

          raise "No broker with ID=#{@broker_id} found" if !broker_node

          log 'Scraping broker offices'
          inner_nodes = broker_node.element_children.index_by(&:name)
          offices_node = inner_nodes['offices'] || broker_node.at_css('broker_details offices') # http://www.jdyachts.com/datafeed/datafeed.php - here offices are inside broker_details
          handle_offices(offices_node.element_children)
          advert_nodes = inner_nodes['adverts'].element_children
          log "Found #{advert_nodes.size} boats"
          advert_nodes.each do |advert_node|
            enqueue_job(advert_node: advert_node, office_id: @office_id_by_source_id[advert_node['office_id']])
          end
        end

        def handle_offices(office_nodes)
          user_offices = @user.offices.includes(:address).to_a
          @office_id_by_source_id = {}

          office_nodes.each do |office_node|
            nodes = office_node.element_children.index_by(&:name)
            office_id = office_node['id']
            next if office_id.blank?
            office = user_offices.find { |o| o.source_id == office_id } || @user.offices.new(source_id: office_id)

            office.name = clean_text(nodes['office_name'])
            office.contact_name = (nodes['name'].element_children.map { |node| node.text }.join(' ').strip.presence if nodes['name'])
            office.email = clean_text(nodes['email'])
            office.daytime_phone = clean_text(nodes['daytime_phone'])
            office.evening_phone = clean_text(nodes['evening_phone'])
            office.fax = clean_text(nodes['fax'])
            office.mobile = clean_text(nodes['mobile'])
            office.website = clean_text(nodes['website'])

            office.address ||= Address.new
            address = office.address
            address.line1 = clean_text(nodes['address'])
            address.town_city = clean_text(nodes['town'])
            address.county = clean_text(nodes['county'])
            country_name = clean_text(nodes['country'] || nodes['counrty']) # counrty misspelling is here: http://81.143.47.18/boat/boats-xml/p/2/b/6/k/b987de2d33b17e6ca8aa874d58e51a6c/pk/c93422dd21571cc120a928c6ab047768
            country = (Country.query_with_aliases(country_name).first if country_name)
            log "Country not found: #{country_name}" if !country
            address.country_id = country.try(:id)
            address.zip = clean_text(nodes['postcode'])

            user_offices << office if office.new_record?
            office.save! if office.changed?
            address.save! if address.changed?

            @office_id_by_source_id[office_id] = office.id
          end
        end

        def process_job(job)
          advert_node = job[:advert_node]
          if advert_node['status'] =~ /sold/i
            log 'Boat Sold'
            return
          end

          boat = SourceBoat.new
          boat.office_id = job[:office_id]
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

          media_urls = media_nodes.each_with_object([]) do |node, arr| # some sources has primary media not as first child, eg.: http://www.nya.co.uk/boatsxml.php
            url = node.text
            primary = node['primary']
            primary && primary =~ /true|1|yes/i ? arr.unshift(url) : arr.push(url)
          end

          boat.images = media_urls.map do |url|
            url.strip!
            url = URI.encode(url)
            url.gsub!(/[\[\]]/) { |m| m == '[' ? '%5B' : '%5D' }
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
            if !lang || lang =~ /\A(en|gb)/i || lang == 'ISO-8859-1'
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
          boat.new_boat = read_new_or_used(feature_nodes['new_or_used'].try(:text))
        end

        def handle_boat_features(boat, boat_features)
          boat_features.css('item, rb:item').each do |item|
            attr = DATA_MAPPINGS[item['name']]

            value = item.text.strip
            if item['rb:description'].present?
              value = item['rb:description'].strip if value =~ /true/i
            end
            if (unit = (item['unit'] || item['units']))
              if attr
                value = convert_unit(value, unit)
              else
                value = "#{value} #{unit}"
              end
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

        def clean_text(node)
          str = node.try(:text)
          if str
            str.strip!
            str.presence
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
