# encoding: utf-8

# http://ancanet.com/webfiles/DailyBoatExport/BoatExport.xml

module Rightboat
  module Imports
    module Sources

      class Ancasta < Base
        DATA_MAPPINGS = {
          'Boat_ID' => :source_id,
          'Year' => :year_built,
          'Make' => :manufacturer,
          'Model' => :model,
          'Lengthft' => Proc.new { |boat, item| boat.length_m = convert_unit(item.text, 'ft')},
          'Lengthmt' => :length_m,
          'HullMaterial' => :hull_material,
          'Engine' => Proc.new { |boat, item|
            boat.engine_manufacturer, boat.engine_model = cleanup_string(item.text).split(/ /, 2)
          },
          'Class' => :category,
          'Located' => :location,
          'Country' => :country,
          'Price' => :price,
          'Currency' => :currency,
          'Tax' => :vat_rate,
          'Bridge' => :bridge,
          'Type' => :boat_type,
          'Drives' => :drive_type,
          'Rig' => :rig,
          'Keel' => :keel,
          'Description' => :description,
        }
        def enqueue_jobs
          doc = get('http://ancanet.com/webfiles/DailyBoatExport/BoatExport.xml')
          doc.search("//Boat").each do |item|
            enqueue_job(item.clone)
          end
        end

        def process_job(item)
          boat = SourceBoat.new
          boat.source_id = item['Id']
          description_tags = []
          office_attrs = {}
          item.children.each do |c|
            next unless c.is_a?(Nokogiri::XML::Element)
            attr = DATA_MAPPINGS[c.name]
            value = cleanup_string(c.text).gsub("/n","\n")
            if c.name == 'BcbComments'
              next
            elsif c.name == 'Images'
              image_elements = c.search('.//Image').select do |el|
                el.search('.//Type').text =~ /Image$/
              end
              boat.images = image_elements.map do |el|
                url = cleanup_string(el.search('.//URL').text)
                url.gsub(/\?preset\=.*/, '')
              end
            elsif ['OfficeName', 'Phone', 'Email'].include? c.name
              office_attrs[c.name.underscore.to_sym] = value
            elsif c.name =~ /^Text/
              description_tags << [c.name.gsub(/^Text/, ''), value] unless value.blank?
            elsif !attr
              boat.set_missing_attr(c.name, value)
            elsif attr.is_a?(Proc)
              attr.call(boat, c)
            else
              boat.send("#{attr}=", value)
            end
          end

          office_attrs[:name] = office_attrs.delete(:office_name)
          office_attrs[:daytime_phone] = office_attrs.delete(:phone)
          boat.office = office_attrs

          boat.description ||= ''
          boat.description += description_tags.map {|header, text|
            "<h3>#{header}</h3><p>#{text}</p>"
          }.join

          boat
        end
      end

    end
  end
end
