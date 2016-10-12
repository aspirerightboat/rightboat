module Rightboat
  module Imports
    module Importers
      class Ancasta < ImporterBase

        def self.engine_types
          @engine_types ||= {
              '3D' => 'Tri Diesel',
              '3P' => 'Tri Petrol',
              '1D' => 'Single Diesel',
              '1G' => 'Single LPG',
              '1O' => 'Single Outboard',
              '1P' => 'Single Petrol',
              '2D' => 'Twin Diesel',
              '2O' => 'Twin Outboard',
              '2P' => 'Twin Petrol',
              '2E' => 'Twin Electric',
              '2ES' => 'Twin Electric',
              '1DS' => 'Single Diesel',
              '2DS' => 'Twin Diesel',
              '1OS' => 'Single Outboard',
              '1EP' => 'Single Electric',
              '1ES' => 'Single Electric'
          }
        end

        def self.params_validators
          {source_url: :presence}
        end

        def enqueue_jobs
          # https://ancanet.com/webfiles/DailyBoatExport/BoatExport.xml
          # doc = Nokogiri::XML(open('https://ancanet.com/webfiles/DailyBoatExport/BoatExport.xml'))
          # doc = Nokogiri::XML(open("#{Rails.root}/import_data/new_ancasta.xml"))
          doc = download_feed(@import.param['source_url'].strip)

          log 'Scraping boats'
          doc.root.element_children.each do |boat_node|
            enqueue_job(boat_node: boat_node)
          end
        end

        def process_job(job)
          boat_node = job[:boat_node]
          boat_nodes = boat_node.element_children.index_by(&:name)
          boat = SourceBoat.new(importer: self)
          boat.source_id = boat_node['Id']
          boat.year_built = boat_nodes['Year'].text
          boat.manufacturer = boat_nodes['Make'].text
          boat.model = boat_nodes['Model'].text
          boat.length_m = boat_nodes['Lengthmt'].text
          boat.length_f = boat_nodes['Lengthft'].text
          boat.hull_material = boat_nodes['HullMaterial'].text
          boat.engine = boat_nodes['Engine'].text
          unless (engine_code = boat_nodes['EngineCode'].text).blank?
            boat.engine_type = self.class.engine_types[engine_code]
            boat.engine_count = engine_code[/\d+/]
          end
          if boat_nodes.to_s =~ /diesel/i
            boat.fuel_type = 'Diesel'
          elsif boat_nodes.to_s =~ /gasoline/i
            boat.fuel_type = 'Gasoline'
          end
          boat.category = boat_nodes['Class'].text
          boat.location = boat_nodes['Located'].text
          boat.country = boat_nodes['Country'].text.presence
          boat.price = boat_nodes['Price'].text
          boat.currency = read_currency(boat_nodes['Currency'].text)
          boat.vat_rate = boat_nodes['Tax'].text
          boat.bridge = boat_nodes['Bridge'].text
          boat.boat_type = boat_nodes['Type'].text
          boat.drive_type = boat_nodes['Drives'].text
          boat.rig = boat_nodes['Rig'].text
          boat.keel = boat_nodes['Keel'].text
          boat.images = boat_nodes['Images'].element_children.map do |n|
            url = n.first_element_child.text.sub(/\?.*/, '')
            #image_type = # n.element_children[1].text #=> Default Image | Layout Image | General Image
            {url: url}
          end
          boat.office = {
              name: boat_nodes['OfficeName'].text,
              daytime_phone: boat_nodes['Phone'].text,
              email: boat_nodes['Email'].text,
          }
          boat.description = prepare_description(boat_nodes['Description'].inner_html) || ''
          boat.short_description = boat.description
          %w(TextBridge TextMachinery TextRig TextAccomodation TextInventory BcbComments).each do |nodename|
            node = boat_nodes[nodename]
            if node && node.text.present?
              header = node.name.sub('Text', '')
              header = 'Layout' if header == 'Bridge'
              header = 'Accommodation' if header == 'Accomodation'
              header = 'Brokers Comments' if header == 'BcbComments'
              text = prepare_description(node.inner_html)
              boat.description += "<h3>#{header}</h3>#{text}"
            end
          end
          boat
        end

        def self.currencies
          @currencies ||= {
              'U.S. Dollars' => 'USD',
              'Pounds Sterling' => 'GBP',
              'Euro' => 'EUR',
              'Australian Dollars' => 'AUD',
          }
        end

        def read_currency(str)
          self.class.currencies[str] || (log_error('Unknown currency', str); nil)
        end

        def prepare_description(str)
          if str['&']
            str = CGI.unescapeHTML(str)
            str.gsub!(' & ', ' &amp; ')
          end
          str.gsub!('&nbsp;', ' ')
          str.gsub!(/[\s]{2,}/, ' ')
          str.gsub!('/n', "\n")
          str.strip!
          str.gsub!(/<img[^>]*>/, '')
          str.gsub!(/<a [^>]*>(.*?)<\/a>/, '\1')
          str.gsub!(/<p>\s*<\/p>/, '')
          str = ActionController::Base.helpers.simple_format(str.gsub(/<br[^>]*>/, "\n").strip) if !str['<p>']
          str
        end
      end
    end
  end
end
