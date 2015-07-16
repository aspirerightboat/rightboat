module Rightboat
  module Imports
    module Sources
      class Yachtworld < Base
        MAIN_SITE = "http://www.yachtworld.com"

        DATA_MAPPINGS = {
          "Boat Name" => :name,
          "Hull Material" => :hull_material,
          "Year" => :year_built,
          "Current Price" => Proc.new { |boat, data|
            p = data.match(/^\s*(?<currency>[A-Z\$]{3})[^0-9]*(?<price>[0-9,]+)\s*(?<vat>.*)$/m)
            if p
              boat.currency = p[:currency].to_s.gsub(/\$/,'D')
              vat = cleanup_string(p[:vat]) if p[:vat]
              boat.price = p[:price].to_s.gsub(/[^0-9]/,"").to_i.to_s
            else
              p = data.match(/(?<price>[0-9,]+)\s*(?<vat>.*)$/)
              boat.currency = "GBP"
              if p
                boat.price = p[:price].to_s.gsub(/[^0-9]/,"").to_i.to_s
                vat = cleanup_string(p[:vat]) if p[:vat]
              else
                puts "No match: #{data}"
              end
            end
            puts "VAT: #{vat.inspect}"
            if vat && (vat.to_s.include? "Tax Not Paid")
              boat.vat_rate = "No Tax Paid"
            elsif vat
              boat.vat_rate = vat
            end
          },
          "Engine Brand" => :engine_manufacturer,
          "Engine Model" => :engine_model,
          "Engine Type" =>  :engine_type,
          "Propeller" =>    :propeller,
          "Fuel Type" =>    :fuel_type,
          "Engine/Fuel Type" => Proc.new { |boat, data|
            engines, boat.fuel_type = data.to_s.strip.downcase.split(/\s+/)
            case engines
              when "single"
                boat.engine_count = 1
              when "twin"
                boat.engine_count = 2
            end
          },
          "LOA" => Proc.new { |boat, data|
            if data.to_s.match(/m/)
              boat.instance_variable_set :@_length_m, data.to_s.to_f
            else
              length_ft, length_in = data.to_s.split(/\s*ft\s*/)
              boat.instance_variable_set :@_length_m, (length_ft.to_f * 0.3048 + length_in.to_f * 0.0254).round(2)
            end
          },
          "LWL" => :lwl_m,
          "Beam" => :beam_m,
          "Minimum Draft" => :draft_m,
          "Maximum Draft" => :draft_m,
          "Maximum Speed" => :max_speed,
          "Cruising Speed" => :cruising_speed,
          "Engine(s) Total Power" => :engine_horse_power,
          "Total Power" => :engine_horse_power,
          "Headroom" => :head_room,
          "Number of heads" => :heads,
          "Number of single berths" => :single_berths,
          "Number of double berths" => :double_berths,
          "Year Built" => Proc.new{ |boat, data| boat.year_built = data unless boat.year_built },
          "Engine Hours" => :engine_hours,
          "Displacement" => :displacement_kgs,
          "Ballast" => :ballast,
          "Electrical Circuit" => :electrical_circuit,
          "VehicleRemarketingEngine" => Proc.new { |boat, _|
            boat.engine_count = boat.engine_count ? boat.engine_count + 1 : 1
          },
          "Drive Type" => :drive_type
        }

        def self.validate_param_option
          { homepage_url: :presence }
        end

        def enqueue_jobs
          url = @homepage_url
          while url
            doc = get(url)

            rows = doc.search("table[summary=search_results] tr")
            rows.shift # remove header row

            rows.each do |row|
              job = {}
              location = cleanup_string(row.xpath('./td[10]').text)
              next if location == 'Sold' || location == 'Sale Pending'

              length = cleanup_string(row.xpath('./td[4]').text)
              if length =~ /^(\d+)'(\s(\d+)\s")?$/
                job[:length_m] = ($1.to_f * 0.3048 + $3.to_f * 0.0254).round(2)
              end
              country, _, location = location.rpartition(/\s?,\s?/)
              job[:country] = country.dup
              job[:location] = location.dup
              job[:codes] = row.xpath('./td[9]').text.strip.split(nbsp_char)
              job[:source_url] = doc.uri.merge(row.search('a').first['href'])

              enqueue_job(job)
            end
            next_link = doc.search("//a[contains(text(), \"Next\")]").first
            if next_link
              url = MAIN_SITE + next_link[:href]
            else
              url = nil
            end
          end
        end

        private
        # processes boat by source id
        def process_job(job)
          source_url = job.delete(:source_url)

          doc = get(source_url)

          if doc.search('span.active_field').select{|x| x.to_s =~ /Sold/}.first
            puts "Sold boat #{source_url}"
            return
          end

          full_spec_link = doc.link_with(href: /pl_boat_full_detail/)
          full_spec_uri = doc.uri.merge(full_spec_link.uri)

          boat = SourceBoat.new(source_url: source_url)

          boat.instance_variable_set :@_length_m, job.delete(:length_m)
          job.merge(parse_codes(job.delete(:codes)))
          job.each do |k, v|
            boat.send "#{k}=", v
          end

          description = "<p>#{doc.search('tr[@align="left"]').first.try(&:text) || ''}</p>"

          doc = get(full_spec_uri)
          boat.under_offer = !doc.content.match(/Sale Pending/).nil?
          boat.source_id = url_param(source_url.to_s, :boat_id)
          details = doc.search("div:has(h2)")
          m = doc.search("h3").text.match(/^\s*(?<length>\d{1,3})'/)
          rough_length = m[:length] if m

          begin
            boat.manufacturer, boat.model = doc.search("h3").first.text.gsub(/^\s*\d+.\s*/,"").split(/\s+/,2)
          rescue
            puts "Couldn't match key field - moving onto next boat..."
            return
          end

          doc.search("td ul li").each do |li|
            label, data = li.text.split(/:/)
            attr = self.class::DATA_MAPPINGS[label]
            next unless attr
            if attr.is_a?(Symbol) || attr.is_a?(String)
              boat.send "#{attr}=", data
            elsif attr.is_a?(Proc)
              attr.call(boat, data)
            else
              @missing_attrs ||= {}
              @missing_attrs[label] ||= []
              @missing_attrs[label] << [data, full_spec_uri.to_s]
            end
          end

          sections = details.inner_html.split(/<strong>/)
          sections.shift
          sections.each do |section|
            if (m = section.to_s.match(/(?<label>.*?)<\/strong>(?<data>.*)/m))
              section_label = m[:label]
              pair_list = []
              if section_label == 'Engines'
                m[:data].split(/<br>([\r\n\t\s]+)?<br>|Engine\s\d\:/).each do |group|
                  data = group.gsub(/<br>/,"")
                  next if data.blank?
                  pair_list += data.scan(/\s*(.*?)\s*:\s*(.*)\s*/).map do |label, data|
                    label == 'Engine/Fuel Type' ? ['Fuel Type', data] : [label, data]
                  end
                end
              else
                pair_list = m[:data].gsub(/<br>/,"").to_s.scan(/\s*(.*?)\s*:\s*(.*)\s*/)
              end

              pair_list.each do |label, data|
                attr = self.class::DATA_MAPPINGS[label]
                next unless attr
                if attr.is_a?(Symbol) || attr.is_a?(String)
                  boat.send "#{attr}=", data
                elsif attr.is_a?(Proc)
                  attr.call(boat, data)
                else
                  @missing_attrs ||= {}
                  @missing_attrs[label] ||= []
                  @missing_attrs[label] << [data, full_spec_uri.to_s]
                end
              end
            end
          end

          doc.search("td:has(b)").map do |detail_tag|
            description += detail_tag.inner_html
          end
          boat.description = description

          length_m = boat.instance_variable_get(:@_length_m)
          unless length_m
            length_ft = rough_length
            l = (length_ft.to_f * 0.3048).round(2)
          end
          boat.length_m = length_m

          boat.images = doc.content.scan(/<img src="(http:\/\/newimages.yachtworld.com[^"]*)"/).flatten.map {|img| img.gsub(/([wh])=(\d+)/,'\1=600')}
          boat
        end

        def parse_codes(codes)
          {
            boat_type: codes[0] == 'P' ? 'Power' : (codes[0] == 'S' ? 'Sail' : nil),
            new_boat: codes[1] == 'N' ? true : false
          }
        end

      end
    end
  end
end
