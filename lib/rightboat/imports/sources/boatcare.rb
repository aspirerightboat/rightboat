# encoding: utf-8

module Rightboat
  module Imports
    module Sources
      class BoatCare < Base
        def advert_url(id)
          "http://www.boatcarelimited.com/module/Brokerage/#{id}/26.htm"
        end

        def homepage_url
          "http://www.boatcarelimited.com/index.php?handler=content&mact=Brokerage,cntnt01,default,0&cntnt01pagelimit=9999&cntnt01itemid=8&cntnt01page=1&cntnt01returnid=26&cntnt01returnid=26"
        end

        def enqueue_jobs
          url = "http://www.boatcarelimited.com/index.php?handler=content&mact=Brokerage,cntnt01,default,0&cntnt01pagelimit=9999&cntnt01itemid=8&cntnt01page=1&cntnt01returnid=26&cntnt01returnid=26"
          doc = get(url)
        end

        def run
          @m = Mutex.new
          ids = get_ids
          puts ids.inspect
          ts = []
          (1..4).each_with_index do |i, j|
            ts << Thread.new do
              while 1
                id = nil
                @m.synchronize { id = ids.pop }
                break if id.nil?
                process_boat id
              end
            end
          end
          ts.map(&:join)
          #@boats.each {|boat| puts boat.inspect}
          #puts "#{@boats.length} boats"
        end

        # retrieves all the source ids from the source site
        def get_ids
          ids=[]
          url = homepage_url
          doc = true
          begin
            while url
              puts url
              doc = open(url).read
              ids << doc.scan(/\/module\/Brokerage\/(\d+)\/26\.htm/i)
              url = doc[/(http:\/\/www.boatcarelimited.com\/index\.php\?[^"]+)"><img src="[^"]+" alt="Next"\/><\/a>/,1]
            end
          rescue SocketError => se
            puts "Unable to retrieve IDs - from url: " + url
            exit 1
          end
          ids.flatten.uniq
        end

        # processes boat by source id
        def process_boat id
          doc = Nokogiri::HTML(open(advert_url id), 'UTF-8')
          return if doc.to_s.match(/Sold/)
          boat = Boat.new
          boat.id = id
          puts advert_url(id)
          manufacturer_model = doc.css(".summary-title").text
          boat.manufacturer, boat.model = manufacturer_model.split(/\s+/,2)
          boat.description = doc.css(".summary-body").text.to_s
          puts "manufacturer: #{boat.manufacturer}"
          puts "model: #{boat.model}"
          summary = doc.css("div.brokerage-summary-text").first.to_s
          details = Hash[summary.scan(/<b>(.*?)\s*<\/b>\s*([^<]*)/)]
          puts details.inspect
          boat.year_built = details["Year of Manufacture:"]
          boat.length_m = details["L.O.A.:"]
          boat.price = details["Price:"].to_s.gsub(/[^0-9\.]/,"")
          boat.currency = "EUR"
          boat.beam_m = details["Beam:"].to_s.gsub(/[^0-9\.]/,"")
          boat.draft_m = details["Draft:"].to_s.gsub(/[^0-9\.]/,"")
          doc.css("a.lightview").each do |a|
            boat.images << "http://www.boatcarelimited.com/#{a["href"].to_s}"
          end
          @m.synchronize { @boats << boat }
        end
      end
    end
  end
end
