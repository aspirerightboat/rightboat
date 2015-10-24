# encoding: utf-8

module Rightboat
  module Imports
    module Sources
      class Eyb < Base
        DATA_MAPPINGS = SourceBoat::SPEC_ATTRS.inject({}) {|h, attr| h[attr.to_s] = attr; h}.merge(
          'id' => :source_id,
          'boat_price' => :price,
          'currency_code' => :currency,
          'vat' => :vat_rate,
          'lying_country_name' => :country,
          'lying_town' => :location,
          'weight' => :dry_weight,
          'hull_name' => :hull_type,
          'model' => :model,
          'builder' => :manufacturer,
          'year_built' => :year_built,
          'name_boat' => :name,
          'length' => :length_m,
          'beam' => :beam_m,
          'draugth' => :draft_m,
          'number_engines' => :engine_count,
          'diesel' => :fuel_type,
          'engine_power' => :engine_horse_power,
          'engine_model' => :engine_model,
          'engine_make' => :engine_manufacturer,
          'hours_engine' => :engine_hours,
          'number_cabins' => :cabins,
          'comments' => :owners_comment,
          'exhibitcomments' => :description
        )

        def self.validate_param_option
          { broker_id: [:presence, /\A\d+\z/]}
        end

        def enqueue_jobs
          doc = get('http://www.eyb.fr/exports/RGB/out/auto/RGB_Out.xml')

          doc.search("An_Broker[text()='#{@import.param['broker_id']}']").each do |broker|
            job = { ad: broker.parent }
            enqueue_job(job)
          end
        end

        def process_job(job)
          doc = job[:ad]
          boat = SourceBoat.new

          doc.children.each do |node|
            key = node.name.gsub('An_', '').downcase
            next if key =~ /^deal/i || key == 'broker'
            val = node.children.text
            next if val.blank?

            if key == 'url_photo'
              boat.images = node.children.map(&:text).reject(&:blank?)
            else
              if (attr = DATA_MAPPINGS[key])
                if attr.is_a?(Proc)
                  attr.call(boat, val)
                else
                  boat.send("#{attr}=", val)
                end
              else
                boat.set_missing_attr(key, val) if val.length < 256 # Ignore long values like "Comments En"
              end
            end
          end

          boat
        end
      end
    end
  end
end