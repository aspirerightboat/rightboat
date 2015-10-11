# encoding: utf-8

module Rightboat
  module Imports
    module Sources
      class Charleswatson < Base
        DATA_MAPPINGS = SourceBoat::SPEC_ATTRS.inject({}) {|h, attr| h[attr.to_s] = attr; h}.merge(
          'boat_name' => :name,
          'boat_reference' => :source_id,
          'build_year' => :year_built,
          'boat_price' => Proc.new { |boat, val| boat.price = val.gsub(/,/, '').to_f; boat.currency = val[/[a-zA-Z]{3}/] },
          'vat_status' => Proc.new { |boat, val| boat.vat_rate = true if val =~ /^paid/i },
          'hull_construction' => :hull_type,
          'builder' => :builder,
          'designer' => :designer,
          'loa' => Proc.new { |boat, val| boat.set_missing_attr(:loa_m, get_value_m(val)) },
          'lwl' => Proc.new { |boat, val| boat.lwl_m = get_value_m(val) },
          'beam' => Proc.new { |boat, val| boat.beam_m = get_value_m(val) },
          'displacement' => Proc.new { |boat, val| boat.displacement_kgs = get_value_m(val) },
          'ballast' => :ballast,
          'engine(s)' => :engine_count,
          'engine_horsepower' => :engine_horse_power,
          'fuel_type' => :fuel_type,
          'lying' => Proc.new do |boat, val|
            if (tmp = val.split(',')).length > 0
              boat.location = tmp[0].strip
              boat.country = tmp[1].strip rescue nil
            end
          end
        )

        def host
          'www.charleswatsonmarine.co.uk'
        end

        def enqueue_jobs
          url = 'http://www.charleswatsonmarine.co.uk/results.asp?bit=3'
          begin
            log "Parsing #{url}"
            doc = get(url)

            doc.search('article[@id="mainContent"] table tr td a').each do |a|
              unless (detail_page = a['href']).blank?
                job = { url: "/#{detail_page}" }
                enqueue_job(job)
              end

            end
          rescue SocketError => e
            log_error "#{e.message} Error: Cannot retrieve IDs - verify source id parameter in #{url}", 'Cannot retrieve IDs'
            exit 1
          end
        end

        def self.get_value_m(value)
          value.to_f rescue nil
        end

        def process_job(job)
          url = job[:url]
          boat = SourceBoat.new
          fields = {}
          url = advert_url(url)
          boat.source_url = url
          doc = get(url)

          boat.manufacturer_model = doc.search('article[@id="mainContent"] h2').first.text.strip rescue nil

          doc.search("td.tdTitle").each do |key_td|
            key = key_td.text.strip.gsub(/((\s+)?:$|\.)/, '').gsub(/(\s+|\/)/, '_').downcase
            value = key_td.next.next.text.strip rescue nil
            fields[key] =  value unless key.blank? || value.blank?
          end

          description = ''
          doc.search('article[@id="mainContent"] .paddingTB').each_with_index do |row, i|
            next if i == 0 || i > 8
            description += row.search('h2').first.to_s + row.search('p').first.to_s
          end
          boat.description = description

          boat.images = []
          boat.images << advert_url(doc.search('article[@id="mainContent"] p > img').first.attr('src'))
          boat.images += doc.search('a.group1 img').map do |img|
            advert_url(img['src'])
          end.reject(&:blank?)

          fields.each do |key, val|
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

          boat
        end
      end
    end
  end

end
