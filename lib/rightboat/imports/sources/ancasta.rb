module Rightboat::Imports
  class Sources::Ancasta < Base
    include ActionView::Helpers::TextHelper # for simple_format

    def enqueue_jobs
      log 'Loading XML file'
      doc = get('http://ancanet.com/webfiles/DailyBoatExport/BoatExport.xml')

      log 'Scraping boats'
      doc.xml.root.element_children.each do |boat_node|
        enqueue_job(boat_node)
      end
    end

    def process_job(boat_node)
      boat_nodes = boat_node.element_children.index_by(&:name)
      boat = SourceBoat.new
      boat.source_id = boat_node['Id']
      boat.year_built = boat_nodes['Year'].text
      boat.manufacturer = boat_nodes['Make'].text
      boat.model = boat_nodes['Model'].text
      boat.length_m = boat_nodes['Lengthmt'].text
      boat.hull_material = boat_nodes['HullMaterial'].text
      boat.engine = boat_nodes['Engine'].text
      boat.engine_code = boat_nodes['EngineCode'].text
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
      boat.images = boat_nodes['Images'].element_children.map { |n| n.first_element_child.text.sub(/\?.*/, '') }
      boat.office = {
        name: boat_nodes['OfficeName'].text,
        daytime_phone: boat_nodes['Phone'].text,
        email: boat_nodes['Email'].text,
      }
      descr = fix_whitespace(boat_nodes['Description'].inner_html)
      descr = simple_format(descr.gsub('<br />', "\n").strip) if !descr['<p>']
      boat.description = descr
      boat_node.element_children.select { |n| n.name.start_with?('Text') }.map do |node|
        if node.text.present?
          header = node.name.sub('Text', '')
          text = fix_whitespace(node.inner_html)
          boat.description << "<h3>#{header}</h3>#{simple_format text}"
        end
      end
      boat
    end

    CURRENCIES = {
      'U.S. Dollars' => 'USD',
      'Pounds Sterling' => 'GBP',
      'Euro' => 'EUR',
      'Australian Dollars' => 'AUD',
    }

    def read_currency(str)
      CURRENCIES[str] || (log "Unexpected currency: #{str}"; nil)
    end

    def fix_whitespace(str)
      str.gsub(/[\s]+|&nbsp;/, ' ').squeeze.gsub('/n', "\n").strip
    end
  end
end