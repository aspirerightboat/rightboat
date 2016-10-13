module Rightboat
  module Imports
    module Importers
      class Boatmatch < ImporterBase

        def self.data_mappings
          @data_mappings ||= {
              'id' => :source_id,
              'url' => :source_url,
              'taxstatus' => ->(boat, v) { boat.vat_rate = v.to_s =~ /^(na)?$/i ? nil : v },
              'fuel' => :fuel_type,
              'year' => :year_built,
              'type' => :boat_type,
              'description' => :description,
              'lying' => ->(boat, v) do
                tmp = v.split(',')
                boat.country = tmp.last&.strip
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
              'displacement' => :displacement_kgs,
              'hullmaterial' => :hull_material,
              'wherebuilt' => :where_built,
              'tankcapacityfuel' => :fuel_tanks_capacity,
              'tankcapacitywater' => :water_tanks_capacity,
              'tankcapacityholding' => :holding_tanks_capacity,
              'designer' => :designer,
              'url_pic' => ->(boat, v) do
                boat.images ||= []
                boat.images << {url: v}
              end
          }
        end

        def enqueue_jobs
          basic_auth('rightboat', 'bo4t_fe3d_rB')
          doc = get('http://www.boatmatch.com/xml_feed')
          doc.xml.root.element_children.each do |item|
            enqueue_job(item: item)
          end
        end

        def process_job(job)
          boat = SourceBoat.new(importer: self)

          job[:item].element_children.each do |c|
            key = c.name
            val = c.text
            next if val.blank?
            val.squeeze_whitespaces!.strip!

            if (attr = self.class.data_mappings[key])
              if attr.is_a?(Proc)
                attr.call(boat, val)
              else
                boat.send("#{attr}=", val)
              end
            else
              if key =~ /unit$/
                attr = key.gsub(/unit$/, '')
                if %w(length beam draft lwl).include?(attr)
                  attr_m = attr + '_m'
                  cv = convert_unit(boat.send(attr_m), val)
                  boat.send("#{attr_m}=", cv)
                else
                  if (renamed_attr = self.class.data_mappings[attr])
                    cv = convert_unit(boat.send(renamed_attr), val)
                    boat.send("#{renamed_attr}=", cv)
                  else
                    boat.set_missing_attr(key, val)
                  end
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
