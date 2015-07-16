# encoding: utf-8

module Rightboat
  module Imports
    module Sources

      class Openmarine < Base
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
          doc = get(@url)
          if @broker_id.blank? || @broker_id == "all"
            brokers = doc.search("//broker")
          else
            brokers = doc.search("//broker[@code=\"#{@broker_id}\"]")
          end
          brokers.each do |broker|
            broker.search(".//adverts/advert").each do |advert|
              job = {
                advert: advert.clone,
                offices: broker.search('.//office').inject({}) do |office_h, office|
                  office_attrs = office.children.inject({}) {|attr_h, el|
                    key = el.name == 'counrty' ? :country : el.name.to_sym # fix misspelling
                    attr_h[key] = cleanup_string(el.text) if el.is_a? Nokogiri::XML::Element
                    attr_h
                  }
                  office_attrs[:contact_name] = office_attrs.delete(:name)
                  office_attrs[:name] = office_attrs.delete(:office_name)
                  address_attributes = {}
                  [:address, :town, :county, :country, :postcode].each do |addr_key|
                    v = office_attrs.delete addr_key
                    address_attributes[addr_key] = v unless v.blank?
                  end
                  office_attrs[:address_attributes] = address_attributes if Address.new(address_attributes).valid?
                  office_h[office['id']] = office_attrs
                  office_h
                end
              }
              enqueue_job(job)
            end
          end
        end

        def process_job(job)
          advert = job[:advert]
          offices = job[:offices]

          return if advert['status'] == 'Sold' # skip sold boats

          boat = SourceBoat.new
          boat.office = offices[advert["office_id"]]
          media_tags = advert.xpath('advert_media/media[not(starts-with(@type, "video/"))]')
          primary_media = media_tags.select{ |x| x['primary'].to_s =~ /true|1|yes/i }.first
          media_tags.delete(primary_media) if primary_media
          images = ([primary_media] + media_tags).reject(&:blank?).map(&:inner_html)
          advert_features = advert.search("advert_features")
          boat_features = advert.search("boat_features")
          new_or_used = boat_features.find('new_or_used').first
          boat.new_boat = (new_or_used && cleanup_string(new_or_used.text) =~ /new/i) ? false : true
          boat.source_id = advert['ref']
          images.to_a.each do |image|
            image_url = URI.encode(image).gsub("[","%5B").gsub("]","%5D")
            boat.images ||= []
            unless image =~ /^http(s)?:\/\//
              image_url = URI.parse(@url).merge(image_url).to_s
            end
            boat.images << image_url
          end
          boat.manufacturer = advert_features.search("manufacturer").inner_html #class for inserting boat must deal with processing these according to andy's system
          boat.model = advert_features.at("model").inner_html
          boat.price = advert_features.at("asking_price").inner_html
          boat.currency = advert_features.at("asking_price")["currency"]
          poa = advert_features.at("asking_price")["poa"]
          boat.poa = true if poa.to_s =~ /^(false|0|no)$/i
          boat.description = advert_features.search("marketing_descs/marketing_desc").map do |marketing_desc|
            if !marketing_desc['language'] || marketing_desc['language'] =~ /en/i
              marketing_desc.inner_html.gsub('&lt;br&gt;',"\n")
            end
          end.reject(&:blank?).join("\n")
          if !(url_el = advert_features.at("other/item[@name='external_url']")).nil?
            boat.source_url = url_el.inner_html
          end
          if (boat_type = advert_features.at("boat_type"))
            boat.boat_type = cleanup_string(boat_type.text)
          end
          if (vat_rate = advert_features.at("asking_price")["vat_included"])
            case vat_rate.downcase
              when "true", "inc vat", "1"
                boat.vat_rate = "Inc VAT"
              when "false", "ex vat", "0"
                boat.vat_rate = "Ex VAT"
              else
                raise "Wrong vat value #{vat_rate}"
            end
          end
          if (location_el = advert_features.at("vessel_lying"))
            boat.location = location_el.inner_html
            boat.country = location_el["country"]
          end

          boat_features.xpath('.//item').each do |item|
            attr = DATA_MAPPINGS[item['name']]

            value = cleanup_string(item.text)
            if value.to_s =~ /^true|false$/i && item['rb:description']
              value = cleanup_string(item['rb:description'])
            end
            if (unit = item['unit'] || item['units'])
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

          boat
        end

      end

    end
  end
end
