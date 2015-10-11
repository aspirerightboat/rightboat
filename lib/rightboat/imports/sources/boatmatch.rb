# encoding: utf-8

module Rightboat
  module Imports
    module Sources
      class Boatmatch < Base
        DATA_MAPPINGS = {
          'id' => :source_id,
          'url' => :source_url,
          'taxstatus' => Proc.new do |boat, v|
            boat.vat_rate = v.to_s =~ /^(na)?$/i ? nil : v
          end,
          'fuel' => :fuel_type,
          'year' => :year_built,
          'type' => :boat_type,
          'description' => :description,
          'lying' => Proc.new do |boat, v|
            boat.country, _, boat.location = v.to_s.rpartition(', ')
          end,
          'noofengines' => :engine_count,
          'manufacturer' => :manufacturer,
          'model' => :model,
          'price' => :price,
          'currency' => :currency,
          'url_pic' => Proc.new do |boat, v|
            boat.images ||= []
            boat.images << v
          end
        }

        def enqueue_jobs
          basic_auth('rightboat', 'bo4t_fe3d_rB')
          doc = get('http://www.boatmatch.com/xml_feed')
          doc.search("//boat").each do |item|
            enqueue_job(item.clone)
          end
        end

        def process_job(item)
          boat = SourceBoat.new

          item.children.each do |c|
            next unless c.is_a?(Nokogiri::XML::Element)
            attr = DATA_MAPPINGS[c.name]
            value = cleanup_string(c.text)
            if c.name =~ /unit$/
              attr = c.name.gsub(/unit$/, '')
              next unless attr
              v = (attr == 'length') ? boat.length_m : boat.get_missing_attr(attr)
              cv = convert_unit(v, cleanup_string(c.text))
              attr == 'length' ? boat.length_m = cv : boat.set_missing_attr(attr, cv)
            elsif !attr
              c.name == 'length' ? boat.length_m = value : boat.set_missing_attr(c.name, value)
            elsif attr.is_a?(Proc)
              attr.call(boat, c)
            else
              boat.send("#{attr}=", value)
            end
          end

        end

        class Parser < Nokogiri::XML::SAX::Document
          attr_accessor :boats
          def initialize(member_id, boats, source_id)
            @tree = []
            @member_id = member_id
            @boats = boats
            @source_id = source_id
          end

          def start_element el, attr = []
            @el = el
            @attr = {}
            attr.each do |a|
              k,v = a
              @attr[k] = v
            end
            @char = ""
            @tree.push(el)
            if el == "boat"
              @boat = Imports::Boat.new
            end
          end

          def characters char
            return if @boat.nil?
            char.strip!
            return if (char.length == 0)
            @char += char
          end

          def process
            return if @boat.nil?
            c = @char.to_s
            #puts "#{@tree.join('>')} = #{@char}"  #useful for debugging
            case @el
              when "id"
                @boat.id = c
              when "manufacturer"
                @boat.manufacturer = c
              when "model"
                @boat.model = c
              when "price"
                @boat.price = c
              when "currency"
                @boat.currency = c.upcase
              when "taxstatus"
                #handle this
                @boat.vat_rate  = c
              when "fuel"
                @boat.fuel_type = c
              when "year"
                @boat.year_built = c
              when "lying"
                @boat.location, @boat.country = c.split(/\s*,\s*/)
              when "description"
                @boat.description = c
              when "length"
                @boat.length_ft_in = c
              # @boat.length_m = c.to_f*0.3048
              when "beam"
                @boat.beam_ft = c
              when "draft"
                @boat.draft_ft = c
              when "displacement"
                @boat.displacement_kgs = c
              when "url_pic"
                @boat.images << c
            end
          end

          def end_element el
            @last_char = @char
            process
            @tree.pop
            if el == "boat" && @boat
              @boats << @boat.dup
              @boat = nil
            end
          end
        end

        def process_advert id
          #NOT SURE HOW THIS IS GOING TO WORK YET
        end

        def get_ids
          @adverts.map(&:ref)
        end
      end
    end
  end
end
