# encoding: utf-8

module Rightboat
  module Imports
    module Sources
      class Boatcare < Base
        DATA_MAPPINGS = SourceBoat::SPEC_ATTRS.inject({}) {|h, attr| h[attr.to_s] = attr; h}.merge(
          'year_of_manufacture' => :year_built,
          'engine' => :engine_type,
          'loa' => Proc.new { |boat, val| boat.set_missing_attr(:loa_m, get_value_m(val)) },
          'beam' => Proc.new { |boat, val| boat.beam_m = get_value_m(val) },
          'more_info' => Proc.new {},
          'price' => Proc.new do |boat, val|
            tmp = val.split('-')
            if tmp[0]
              boat.price = tmp[0].gsub(/[^\d\.]/, '')
              boat.currency = tmp[0].gsub(/\d+|\,/, '').strip
            end
            boat.vat_rate = true if tmp[1] and tmp[1] =~ /vat paid/i
          end
        )

        def host
          'www.boatcareltdmalta.com'
        end

        def enqueue_jobs
          url = 'http://www.boatcareltdmalta.com/en/boats-for-sale-malta.htm'

          begin
            while url
              log "Parsing #{url}"
              doc = get(url)
              doc.search('div.divPreview2 > a').each do |a|
                unless (detail_page = a['href']).blank?
                  job = { url: detail_page }
                  enqueue_job(job)
                end
              end

              next_link = doc.search('#pagination .fr a').first
              url = next_link ? next_link['href'] : nil
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
          boat.source_id = url[/([a-zA-Z0-9\-\.]+$)/].gsub(/\.htm/, '')
          url = advert_url(url)
          boat.source_url = url
          #doc = get(url)
          doc = Nokogiri::HTML(open('log.html'))

          boat.manufacturer_model = doc.search('div[@id="page-content2-title"]').first.text.strip rescue nil

          doc.search('.brok-value').each do |value_td|
            key = value_td.previous.previous.previous.text.strip.gsub(/((\s+)?:$|\.)/, '').gsub(/(\s+|\/)/, '_').downcase
            value = value_td.text.strip
            fields[key] =  value unless key.blank? || value.blank?
          end

          boat.description = doc.search('div[@id="page-content2-lower"]').first.children.to_s rescue ''
          boat.images = doc.search('a.lightview img').map do |img|
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
