require 'nokogiri'
require 'open_uri_redirections'

namespace :import do
  desc 'Import currency exchange rates from CurrenciesDirect.com'
  task currency: :environment do
    url = 'http://www.currenciesdirect.com/common/rates.aspx?code=A04190&pass=A04190&base=GBP'
    doc = Nokogiri::XML(open(url, allow_redirections: :safe))

    doc.root.element_children.each do |price|
      unit_name = price.at_css('unit').text
      if (c = Currency.cached_by_name(unit_name))
        c.rate = price.at_css('rate').text.to_f
        c.save!
      end
    end
  end

  # desc 'updates the approximate gbp value of boat for searching and sorting'
  # task :update_boats => :environment do
  #   ActiveRecord::Base.connection.execute('UPDATE boats LEFT JOIN currencies ON boats.currency_id=currencies.id set approximate_price_in_gbp=boats.price/currencies.rate_from_pound')
  # end
end
