require 'nokogiri'
require 'open_uri_redirections'

namespace :import do
  desc "Import currency exchange rates from CurrenciesDirect.com"
  task :currency => :environment do
    url = "http://www.currenciesdirect.com/common/rates.aspx?code=A04190&pass=A04190&base=GBP"
    doc = Nokogiri::HTML(open(url, allow_redirections: :safe))

    doc.css("price_history").each do |price|
      unit_name = price.css('unit').first.content
      if c = Currency.cached_by_name(unit_name)
        c.rate = price.css('rate').first.content
        c.save
      end
    end
  end

  desc "updates the approximate gbp value of boat for searching and sorting"
  task :update_boats => :environment do
    ActiveRecord::Base.connection.execute("update boats LEFT JOIN currencies ON boats.currency_id=currencies.id set approximate_price_in_gbp=boats.price/currencies.rate_from_pound")
  end
end
