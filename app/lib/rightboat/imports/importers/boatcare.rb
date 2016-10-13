module Rightboat
  module Imports
    module Importers
      class Boatcare < ImporterBase

        def self.data_mappings
          @data_mappings ||= SourceBoat::SPEC_ATTRS.inject({}) { |h, attr| h[attr.to_s] = attr; h }.merge(
              'year_of_manufacture' => :year_built,
              'engine' => :engine_type,
              'loa' => ->(boat, val) { boat.set_missing_attr(:loa_m, get_value_m(val)) },
              'beam' => ->(boat, val) { boat.beam_m = get_value_m(val) },
              'more_info' => -> {},
              'price' => ->(boat, val) do
                tmp = val.split('-')
                if tmp[0]
                  boat.price = tmp[0].gsub(/[^\d\.]/, '')
                  boat.currency = tmp[0].gsub(/\d+|\,/, '').strip
                end
                boat.vat_rate = true if tmp[1] and tmp[1] =~ /vat paid/i
              end
          )
        end

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
                  enqueue_job(url: detail_page)
                end
              end

              next_link = doc.search('#pagination .fr a').first
              url = next_link ? next_link['href'] : nil
            end
          rescue SocketError
            log_error 'Cannot retrieve IDs', "Verify source id parameter in #{url}"
            raise
          end
        end

        def self.get_value_m(value)
          value.to_f rescue nil
        end

        def process_job(job)
          url = job[:url]
          boat = SourceBoat.new(importer: self)
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
          images = []
          doc.search('a.lightview img').map do |img|
            url = advert_url(img['src'])
            images << {url: url} if url
          end
          boat.images = images

          fields.each do |key, val|
            if (attr = self.class.data_mappings[key])
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
