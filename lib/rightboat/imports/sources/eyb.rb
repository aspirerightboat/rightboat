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

        def enqueue_jobs
          file_name = Rails.root.join('tmp', 'eyb.xml')

          puts "parsing #{file_name}"
          f = File.open(file_name)
          doc = Nokogiri::XML(f) do |config|
            config.strict.noblanks
          end
          f.close

          doc.search('AD').each do |ad|
            job = { ad: ad }
            enqueue_job(job)
          end
        end

        def process_job(job)
          doc = job[:ad]
          boat = SourceBoat.new
          office_attrs = {}

          doc.children.each do |node|
            key = node.name.gsub('An_', '').downcase

            if key == 'url_photo'
              boat.images = node.children.map(&:text).reject(&:blank?)
            elsif key =~ /^deal/i
              key = key.gsub(/deal_/, '')
              next if ['zipcode', 'country_name', 'country', 'contact2', 'city', 'adr1', 'adr2', 'adr3', 'pending'].include?(key)
              val = node.children.text
              key = 'daytime_phone' if key == 'phone'
              key = 'contact_name' if key == 'contact1'
              key = 'email' if key == 'email1'
              office_attrs[key.to_sym] = val
            else
              val = node.children.text
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
          end

          boat.office = office_attrs
          boat
        end
      end
    end
  end
end