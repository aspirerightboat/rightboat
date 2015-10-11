# encoding: utf-8

module Rightboat
  module Imports
    module Sources
      class Yatco < Base
        DATA_MAPPINGS = SourceBoat::SPEC_ATTRS.inject({}) {|h, attr| h[attr.to_s] = attr; h}.merge(
          'category' => :category,
          'yearbuilt' => :year_built,
          'country' => :country,
          'weight' => :dry_weight,
          'model' => :model,
          'manufacturer' => :manufacturer,
          'fuel_type' => :fuel_type,
          'hull_configuration' => :hull_type,
          'length' => Proc.new { |boat, val| boat.length_m = get_value_m(val) },
          'lwl' => Proc.new { |boat, val| boat.lwl_m = get_value_m(val) },
          'beam' => Proc.new { |boat, val| boat.beam_m = get_value_m(val) },
          'loa' => Proc.new { |boat, val| boat.set_missing_attr(:loa_m, get_value_m(val)) },
          'max_draft' => Proc.new { |boat, val| boat.draft_m = get_value_m(val) },
          'mfg_length' => Proc.new { |boat, val| boat.set_missing_attr(:mfg_length_m, get_value_m(val)) }
        )

        def initialize(import)
          super
          @_agent.user_agent_alias = 'Mac Safari'
        end

        def host
          'www.yatco.com'
        end

        def enqueue_jobs
          base_url = "http://www.yatco.com/search?NR=3"
          url = base_url
          page_num = 0

          begin
            while url
              log "Parsing #{url}"
              doc = get(url)

              doc.search(".article-2colresult a.vessel-details-link").each do |a|
                unless (detail_page = a['href']).blank?
                  job = { url: detail_page }
                  enqueue_job(job)
                end
              end

              next_link = doc.search('li.next')[2]
              if next_link['style'] and next_link['style'] =~ /display:(\s+)?none/
                url = nil
              else
                button = next_link.search('button').first
                page_num = button['onclick'][/\d+/].to_i
                url = base_url + "&pg=#{page_num}"
              end
            end
          rescue SocketError => e
            log_error "#{e.message} Error: Cannot retrieve IDs - verify source id parameter in #{url}", 'Cannot retrieve IDs'
            exit 1
          end
        end

        def self.get_value_m(value)
          value[/[\d+\.]+(\s+)?m/].gsub('m', '')
        end

        def process_job(job)
          url = job[:url]
          boat = SourceBoat.new
          fields = {}
          boat.source_id = url[/\d+/].to_s
          url = advert_url(url)
          boat.source_url = url
          doc = get(url)

          boat.name = doc.search('.request-bar .container h1').text.strip rescue ''
          if (location = doc.search('.request-bar .container li')[3].text.strip rescue nil)
            tmp = location.split(',')
            if tmp.length > 1
              boat.country = tmp.last.strip
              boat.location = tmp[0..-2].join(',')
            else
              boat.location = location
            end
          end

          if (price = doc.search('.request-bar .container li.price').text.strip rescue nil)
            boat.price = price.gsub(/[^0-9\.]/, '').to_f
            boat.currency = price[0]
          end

          return if boat.price.blank? or boat.price == 0

          if desc = doc.search('.accordions table')
            boat.description = desc.first.to_s
          end

          doc.search(".details .tab-content tr").each do |tr|
            tds = tr.search('td')
            key = tds[0].text.strip.gsub(/((\s+)?:$|\.|\s+\#)/, '').gsub(/(\s+|\/)/, '_').downcase
            value = tds[1].text.strip
            fields[key] =  value unless key.blank? || value.blank? || ['--', 'N/A'].include?(value)
          end

          boat.images = doc.search('.photo-gallery a.vespic').map do |img_link|
            img_link['href']
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

          description = ''
          doc.search('.accordions > .content').each do |content|
            description += content.to_s.gsub(/(\s+)?style=\"(.*)\"/, '')
          end
          boat.description = description

          boat
        end
      end
    end
  end
end
