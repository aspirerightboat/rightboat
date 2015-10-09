require 'open-uri'

namespace :db do
  task import: :environment do
    class V1Base < ActiveRecord::Base
      self.abstract_class = true
      establish_connection "v1_#{Rails.env}"
    end

    class V1ArticleAuthor < V1Base
      self.table_name = 'article_authors'
    end

    class V1ArticleCategory < V1Base
      self.table_name = 'article_categories'
    end

    class V1Article < V1Base
      self.table_name = 'articles'
      belongs_to :category, class_name: 'V1ArticleCategory', foreign_key: :article_category_id
      belongs_to :author, class_name: 'V1ArticleAuthor', foreign_key: :article_author_id
    end

    class V1User < V1Base
      self.table_name = 'members'
      belongs_to :country, class_name: 'V1Country', foreign_key: :country_id
      has_many :boats, class_name: 'V1Boat', foreign_key: :member_id
      has_many :imports, class_name: 'V1Imort', foreign_key: :member_id
    end

    class V1Manufacturer < V1Base
      self.table_name = 'boat_manufacturers'
      has_many :models, class: 'V1Model', foreign_key: :boat_manufacturer_id
    end

    class V1Model < V1Base
      self.table_name = 'boat_models'
      has_many :boats, class_name: 'V1Boat', foreign_key: :model_id
      belongs_to :manufacturer, class_name: 'V1Manufacturer', foreign_key: :boat_manufacturer_id
    end

    class V1BoatImage < V1Base
      self.table_name = 'boat_images'
      belongs_to :boat, class_name: 'V1Boat', foreign_key: :boat_id
    end

    class V1Boat < V1Base
      self.table_name = 'boats'
      has_many :boat_images, class_name: 'V1BoatImage', foreign_key: :boat_id
      belongs_to :manufacturer, class_name: 'V1Manufacturer'
      belongs_to :model, class_name: 'V1Model'
      belongs_to :country, class_name: 'V1Country'
      belongs_to :currency, class_name: 'V1Currency'
      belongs_to :user, class_name: 'V1User', foreign_key: :member_id
    end

    class V1Country < V1Base
      self.table_name = 'countries'
      has_many :boats, class_name: 'V1Boat', foreign_key: :country_id
    end

    class V1Currency < V1Base
      self.table_name = 'currencies'
      has_many :boats, class_name: 'V1Boat', foreign_key: :currency_id
    end

    class V1Import < V1Base
      self.table_name = 'imports'
      serialize :param, Hash
      belongs_to :user, class_name: 'V1User', foreign_key: :member_id
    end

    V1Import.find_each do |v1_import|
      find_or_create_import(v1_import)
    end

    V1Currency.find_each do |v1_currency|
      find_or_create_currency(v1_currency)
    end

    V1Country.find_each do |v1_country|
      find_or_create_country(v1_country)
    end

    V1User.find_each do |v1_user|
      find_or_create_user(v1_user)
    end

    V1Article.find_each do |v1_article|
      find_or_create_article(v1_article)
    end

    V1Boat.where('deleted <> true').find_each do |v1_boat|
      user = find_or_create_user(v1_boat.user)
      boat = Boat.unscoped.where(user_id: user.id, source_id: v1_boat.source_id).first_or_initialize
      normal_attrs = [:featured, :location, :geo_location, :year_built, :price, :recently_reduced, :description]
      attributes = {
          description: :description,
          manufacturer_id: Proc.new{|v1_b| find_or_create_manufacturer(v1_b.manufacturer).id},
          country_id: Proc.new{|v1_b| find_or_create_country(v1_b.country).id},
          currency_id: Proc.new{|v1_b| find_or_create_currency(v1_b.currency).id},
          model_id: Proc.new{|v1_b| find_or_create_model(v1_b.model).id},
          deleted_at: Proc.new{|v1_b| v1_b.deleted? ? v1_b.updated_at : nil}
      }
      normal_attrs.each{ |attr| boat.send("#{attr}=", v1_boat.send(attr)) }
      attributes.each{ |key, source|
        source.is_a?(Proc) ? boat.send("#{key}=", source.call(v1_boat)) : boat.send("#{key}=", v1_boat.send(source))
      }
      boat.save(validate: false)

      boat.boat_images.destroy_all
      v1_boat.boat_images.each do |v1_img|
        img = boat.boat_images.new
        img.http_last_modified = v1_img.http_last_modified
        img.source_ref = v1_img.image_reference
        img.source_url = v1_img.source_url
        img.position = v1_img.display_order
        img.save(validate: false)
      end
    end
  end
end

def find_or_create_manufacturer(v1_manufacturer)
  return Manufacturer.new unless v1_manufacturer
  puts "Create Manufacturer: #{v1_manufacturer.name}"
  mu = Manufacturer.where(name: v1_manufacturer.name).first_or_initialize
  mu.assign_attributes(
        description: v1_manufacturer.description,
        weburl: v1_manufacturer.company_website
  )
  mu.remote_logo_url = remote_image_url(v1_manufacturer.logo_image_reference) unless v1_manufacturer.logo?
  mu.save(validate: false)
  mu
end

def find_or_create_model(v1_model)
  return Model.new unless v1_model
  puts "Create Model: #{v1_model.name}"
  mu = find_or_create_manufacturer(v1_model.manufacturer)
  model = mu.models.where(name: v1_model.name).first_or_initialize
  model.save(validate: false)
  model
end

def find_or_create_country(v1_country)
  return Country.new unless v1_country
  puts "Create Country: #{v1_country.iso}"
  c = Country.where(iso: v1_country.iso).first_or_initialize
  c.name = v1_country.name
  c.description = v1_country.description
  c.save(validate: false)
  c
end

def find_or_create_article_author(v1_author)
  return ArticleAuthor.new unless v1_author
  attrs = v1_author.attributes.except('id')
  img_ref = attrs.delete 'image_reference'
  author = ArticleAuthor.where(
    name: attrs['name'],
    created_at: attrs['created_at']
  ).first_or_initialize
  if author.new_record? || (!img_ref.blank? && !author.photo?)
    author.photo = remote_image(img_ref) unless img_ref.blank?
    author.update_attributes!(attrs)
  end
  author
end

def find_or_create_article_category(v1_category)
  return ArticleCategory.new unless v1_category
  attrs = v1_category.attributes.except('id')
  category = ArticleCategory.where(
    name: attrs['name'],
    created_at: attrs['created_at']
  ).first_or_initialize
  category.update_attributes!(attrs) if category.new_record?
  category
end

def find_or_create_article(v1_article)
  attrs = v1_article.attributes.except('id', 'article_category_id', 'article_author_id')
  img_ref = attrs.delete('image_reference')
  article = Article.where(
    title: attrs['title'],
    created_at: attrs['created_at']
  ).first_or_initialize
  if article.new_record? || (!img_ref.blank? && !article.image?)
    attrs['article_category_id'] = find_or_create_article_category(v1_article.category).id
    attrs['article_author_id'] = find_or_create_article_author(v1_article.author).id
    article.image = remote_image(img_ref) unless img_ref.blank?
    article.update_attributes!(attrs)
  end
  article
end

def find_or_create_currency(v1_currency)
  return Currency.new unless v1_currency
  puts "Create Currency: #{v1_currency.code}"
  c = Currency.where(name: v1_currency.code).first_or_initialize
  c.rate = v1_currency.rate_from_pound
  c.symbol = v1_currency.entity
  c.save(validate: false)
  c
end

def find_or_create_import(v1_import)
  cron_sets = {
    'http://www.eyb.fr/exports/RGB/out/auto/RGB_Out.xml' => '/var/scrapedata/eyb/data.xml',

    # /home/rightwebdesign/bin/theyachtmarket.py
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=16892&username=absme&password=notxu"=>"/var/scrapedata/theyachtmarket/14880.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=437&username=AM&password=R2R-ILTMI"=>"/var/scrapedata/theyachtmarket/1331.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=7212&username=CHPMNK&password=CHMPIN"=>"/var/scrapedata/theyachtmarket/9477.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=14841&username=CYS&password=RghtBt"=>"/var/scrapedata/theyachtmarket/7841.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=10582&username=DCYFR&password=ITBCWMK"=>"/var/scrapedata/theyachtmarket/14643.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=14638&username=DDZ&password=BFS"=>"/var/scrapedata/theyachtmarket/5756.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=2872&username=Dlpn&password=2111"=>"/var/scrapedata/theyachtmarket/9776.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=7814&username=MWDMG&password=FrnMrna"=>"/var/scrapedata/theyachtmarket/5759.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=1487&username=premier&password=ujgs421y"=>"/var/scrapedata/theyachtmarket/6296.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=14719&username=ES&password=AIREPX"=>"/var/scrapedata/theyachtmarket/10153.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=15520&username=JRY&password=SAaLBL"=>"/var/scrapedata/theyachtmarket/12984.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=13769&username=lpbs&password=CrzyTwn"=>"/var/scrapedata/theyachtmarket/9623.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=7756&username=PBCLTBH&password=AIEIWALY"=>"/var/scrapedata/theyachtmarket/14442.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=8189&username=RamsOTE&password=TTRightboat"=>"/var/scrapedata/theyachtmarket/12478.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=14981&username=RU&password=FTYM"=>"/var/scrapedata/theyachtmarket/14040.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=3229&username=SHYB&password=DPOYAB"=>"/var/scrapedata/theyachtmarket/6089.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=17918&username=GTTC&password=ITOWOOH"=>"/var/scrapedata/theyachtmarket/14206.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=16473&username=Wolf&password=Rock"=>"/var/scrapedata/theyachtmarket/13607.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=10278&username=YS1111&password=swgaf"=>"/var/scrapedata/theyachtmarket/6545.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=10990&username=Ardyac&password=Yachta"=>"/var/scrapedata/theyachtmarket/14868.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=11337&username=cbb159&password=951cbb"=>"/var/scrapedata/theyachtmarket/14884.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=14423&username=vanlin&password=lewon"=>"/var/scrapedata/theyachtmarket/14917.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=411&username=WYSRightBoat&password=hflop97"=>"/var/scrapedata/theyachtmarket/311.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=9504&username=btkey&password=helwng"=>"/var/scrapedata/theyachtmarket/14886.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=5993&username=arhumfd&password=S4tvd3"=>"/var/scrapedata/theyachtmarket/15102.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=2415&username=a3f6h&password=l8g4"=>"/var/scrapedata/theyachtmarket/8379.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=947&username=WPM&password=GTCHA"=>"/var/scrapedata/theyachtmarket/15079.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=499&username=CIBS&password=RB122"=>"/var/scrapedata/theyachtmarket/5177.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=16921&username=rfb5b&password=v45fh5"=>"/var/scrapedata/theyachtmarket/15254.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=15832&username=a2g4548&password=d4hj85tg"=>"/var/scrapedata/theyachtmarket/15257.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=569&username=sd34v&password=44f34"=>"/var/scrapedata/theyachtmarket/15259.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=14405&username=nj0o3e&password=u8uf4"=>"/var/scrapedata/theyachtmarket/15290.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=20812&username=df34&password=f34"=>"/var/scrapedata/theyachtmarket/15243.xml",
    "http://www.theyachtmarket.com/datafeeds/openmarine/1.7/export.aspx?brokerCode=7777&username=oimobcisrvfsg&password=boehigfsgggdf"=>"/var/scrapedata/theyachtmarket/15073.xml",

    # /usr/local/bin/boatstream - this requires sftp rightboats@elba.boats.com
    "http://ancanet.com/webfiles/DailyBoatExport/BoatExport.xml" => '/var/scrapedata/ancasta.xml',
    "http://www.idealboat.com/theyachtmarket_feed.php" => '/var/scrapedata/openmarine/15243.xml',
    "http://boatconnection.rightboatexpert.com/exports/c6c433b91c3666fe236a138e6d8d102680d3f1c7.xml"  => '/var/scrapedata/openmarine/7445.xml',
    "http://boatcrm.com/Grange/GI_export_om_rb.xml" => '/var/scrapedata/openmarine/417.xml',
    "http://boatcrm.valwyattmarine.co.uk/export/vwm_om_rb.xml" => '/var/scrapedata/openmarine/1962.xml',
    "https://services.boatwizard.com/bridge/events/05b76258-2af0-4c63-8e1a-982a7c8a9da6/boats?status=on" => '/var/scrapedata/openmarine/1962.xml',
    "http://broadland.rightboatexpert.com/exports/c716c934db37ba58e7fa5fde3a3f83840973c42d.xml" => '/var/scrapedata/openmarine/15253.xml',
    "http://crm.yachtfocus.com/modules/export_rightboat.php?makelaar=138&password=jEd4Xu24nUcEC"  => '/var/scrapedata/openmarine/9529.xml',
    "https://go.openbms.nl/export/12/?b=20&u=uweycrtby&p=gwtithoicp" => '/var/scrapedata/openmarine/9529.xml',
    "https://go.openbms.nl/export/12/?b=19&u=ioeutbioucwexorp&p=ewyrocewqicrc"  => '/var/scrapedata/openmarine/15815.xml',
    "http://exports.boatshop24.com/xml/openmarine/5286.xml" => '/var/scrapedata/marinaestella.xml',
    "http://moorebrokerage.net/mib_om_cdata.xml" => '/var/scrapedata/openmarine/3466.xml',
    "http://morganmarine.com/portals/portals.xml" => '/var/scrapedata/openmarine/4262.xml',
    "http://om.best-boats24.net/ABCCB8E7-6B14-42dd-A20F-010F426402F2/" => '/var/scrapedata/15410.xml',
    "http://riginosyachts.com/wp-content/uploads/Riginos.xml" => '/var/scrapedata/openmarine/8384.xml',
    "http://81.143.47.18/boat/boats-xml/p/2/b/6/k/b987de2d33b17e6ca8aa874d58e51a6c/pk/c93422dd21571cc120a928c6ab047768" => "/var/scrapedata/openmarine/347.xml",
    "http://sekw.ybroker.co.uk/advert_feed.xml" => '/var/scrapedata/openmarine/9762.xml',
    "https://go.openbms.nl/export/12/?b=103&u=SailingWorld&p=vOGFmjv032fnVE" => '/var/scrapedata/15307',
    "https://go.openbms.nl/export/12/?b=131&u=V44W1Uen0g8eKoA&p=sB8AL13w58z66TO" => '/var/scrapedata/15315',
    "https://go.openbms.nl/export/12/?b=208&u=60m34r7D95201Vj&p=60m34r7D95201Vj" => '/var/scrapedata/15329',
    "https://go.openbms.nl/export/12/?b=226&u=sea&p=qweinl465i6j8o67" => '/var/scrapedata/15289',
    "https://go.openbms.nl/export/12/?b=275&u=Astramare&p=aseioqw4324b5k45b6" => '/var/scrapedata/15295',
    "https://go.openbms.nl/export/12/?b=282&u=Dolman&p=qwe2345edfgcvbty876" => '/var/scrapedata/15264',
    "https://go.openbms.nl/export/12/?b=37&u=sneekerhof&p=ije5o45j76oi56yh7uig" => '/var/scrapedata/15298',
    "http://www.boatmatch.com/xml_feed/" => '/var/scrapedata/15113.xml', # --http-user=rightboat --http-passwd=bo4t_fe3d_rB
    "http://www.carineyachts.com/xml_tmp_third/right-boat_103313987f94d4793d6acf8cb15c2db1.xml" => '/var/scrapedata/openmarine/13066.xml',
    "http://www.doevemakelaar.nl/xml/schepen_en.xml" => '/var/scrapedata/openmarine/15316.xml',
    "http://www.ibcmallorca.com/feeds/openmarine.xml" => '/var/scrapedata/15292 2>/tmp/log',
    "http://www.macasailor.com/openmarine.asp" => '/var/scrapedata/14691.xml',
    "http://www.nya.co.uk/boatsxml.php" => '/var/scrapedata/openmarine/806.xml', "http://ayb.yachthost.co.uk/xml/all_openmarine.xml" => "/var/scrapedata/openmarine/14870.xml",
    "http://eby.ribbs.org/exports/c6c433b91c3666fe236a138e6d8d102680d3f1c7.xml" => '/var/scrapedata/openmarine/1.xml',
    "http://feeds.popyachts.com/Feed/RightBoat.com/XML/C0EB0C58xA64Ex43E9x90A3x25A8748391FB/Feed.xml" => '/var/scrapedata/openmarine/15064.xml',
    "http://sekp.ybroker.co.uk/advert_feed.xml" => '/var/scrapedata/openmarine/13988.xml',
    "http://slhassall.rightboatexpert.com/exports/c6c433b91c3666fe236a138e6d8d102680d3f1c7.xml"  => '/var/scrapedata/openmarine/15145.xml',
    "https://services.boatwizard.com/bridge/events/62aa64e3-de99-4afa-87c4-bc7a22a70c57/boats?status=on" => "/var/scrapedata/nordwest.xml",
    "http://www.inwardsmarine.com/data/Right_Boat.xml" => '/var/scrapedata/openmarine/274.xml',
    "http://www.jdyachts.com/datafeed/datafeed.php" => "/var/scrapedata/openmarine/JD.xml",
    "http://www.western-horizon.co.uk/datafeed/rightboat.xml" => '/var/scrapedata/openmarine/15071.xml',
    "http://www.yachtcouncil.org/RightBoat/right_boat.csv" => '/var/scrapedata/458.csv',
    "https://go.openbms.nl/export/12/?b=191&u=Kelly&p=Sutton" => '/var/scrapedata/openmarine/15504.xml',
    "http://www.boatsandoutboards.co.uk/php/feed/get?feed=RIM001" => '/var/scrapedata/openmarine/5160.xml',
    "http://exports.boatsandoutboards.co.uk/om/1200" => '/var/scrapedata/openmarine/parkstonebay.xml',
    "http://exports.boatshop24.com/om/1355" => '/var/scrapedata/16053.xml',
    "http://exports.boatshop24.com/om/1353" => '/var/scrapedata/16054.xml',
    "http://exports.boatshop24.com/om/1354" => '/var/scrapedata/16055.xml',
    #'/home/rightwebdesign/bin/importall'
    #import:run_type[yachtworld]'
    #import:run_type[boatstream]'
    #import:run_type[boatsandoutboards]'
    #import:run_type[boatshop24]'
    #import:run_type[eyb]'
    #import:run_type[openmarine]'
    #import:run_type[boatmatch]'
    #import:run_type[openmarine_special]'
    #import:eyb_members'
    #import:run[1241]'
    #import:run[15064]'
    #import:run[15145]'
    #import:run[2]'
    #import:run[458]'
    #import:run[8379]'
    #/bin/bash -l -c 'cd /var/www/rightboat.com/current && http_proxy="http://uk.proxymesh.com:31280" RACK_ENV=production bundle exec rake import:run[5160]'
  }

  param = v1_import.param
  k = cron_sets.select{|_, v| v1_import.param.values.include?(v)}.first
  return unless v1_import.import_type == 'yachtworld' || k

  case v1_import.import_type
    when 'openmarine'
      param = {
        broker_id: param[:source_id],
        url: k ? k.first : param[:filename]
      }
    when 'yachtworld'
      param = {
        homepage_url: k ? k.first : param[:homepage_url]
      }
    else
      return
  end

  import = Import.where(
    user_id: find_or_create_user(v1_import.user).id,
    import_type: v1_import.import_type
  ).first_or_initialize
  import.param = param
  import.assign_attributes(v1_import.attributes.except('member_id', 'param'))
  import.save!(validate: false)
  import
end

def find_or_create_user(v1_user)
  puts "Create User: #{v1_user.email_address}"
  user = User.where(email: v1_user.email_address).first_or_initialize
  user.build_broker_info if !user.broker_info
  user.first_name = v1_user.first_name
  user.last_name = v1_user.last_name
  user.company_name = v1_user.company_name
  user.username = v1_user.username
  user.security_question = v1_user.security_question
  user.security_answer = v1_user.security_answer
  user.description = v1_user.description
  user.role = v1_user.membership_type
  user.mobile = v1_user.mobile_number
  user.fax = v1_user.fax_number
  user.phone = v1_user.telephone_number
  user.broker_info.company_weburl = v1_user.company_website
  user.broker_info.description = v1_user.company_description
  user.remote_avatar_url = remote_image_url(v1_user.logo_image_reference) unless user.avatar?
  user.address_attributes = {
      id: user.address.try(&:id),
      line1: v1_user.address1,
      line2: v1_user.address2,
      town_city: v1_user.town_city,
      county: v1_user.county,
      country_id: find_or_create_country(v1_user.country).id,
      zip: v1_user.post_code
  }
  user.save(validate: false)
  user
end

def remote_image_url(hash)
  return if hash.blank?
  "http://images.rightboat.com/images/#{hash[0..1]}/#{hash}/original.jpg"
end

def remote_image(hash)
  url = remote_image_url(hash)
  _file = Tempfile.new(['original', '.jpg'])
  _file.binmode
  _file.write open(url).read
  _file.rewind
  _file
rescue
  nil
end