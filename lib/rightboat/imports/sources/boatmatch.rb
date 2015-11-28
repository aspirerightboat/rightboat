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
            tmp = v.split(',')
            boat.country = tmp.last.try(:strip)
            boat.location = tmp[0..-2].map(&:strip).join(', ')
          end,
          'length' => :length_m,
          'draft' => :draft_m,
          'beam' => :beam_m,
          'lwl' => :lwl_m,
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
          doc.xml.root.element_children.each do |item|
            enqueue_job(item: item)
          end
        end

        def process_job(job)
          boat = SourceBoat.new

          job[:item].element_children.each do |c|
            key = c.name
            val = cleanup_string(c.text)
            next if val.blank?

            if attr = DATA_MAPPINGS[key]
              if attr.is_a?(Proc)
                attr.call(boat, val)
              else
                boat.send("#{attr}=", val)
              end
            else
              if key =~ /unit$/
                attr = key.gsub(/unit$/, '')
                unit = cleanup_string(c.text)
                if %w(length beam draft lwl).include?(attr)
                  attr_m = attr + '_m'
                  cv = convert_unit(boat.send(attr_m), unit)
                  boat.send("#{attr_m}=", cv)
                else
                  cv = convert_unit(boat.get_missing_attr(attr), unit)
                  boat.set_missing_attr(attr, cv)
                end
              else
                boat.set_missing_attr(key, val)
              end
            end
          end

          boat
        end
      end
    end
  end
end
