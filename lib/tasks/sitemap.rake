namespace :rb_sitemap do
  desc 'Create sitemap.xml.gz on import server and copy to prod servers'
  task refresh: :environment do
    SitemapGenerator::Interpreter.run
    `scp #{Rails.root}/public/sitemap.xml.gz rightboat@prod1.rightboat.com:/#{Rails.root}/public/`
    `scp #{Rails.root}/public/sitemap.xml.gz rightboat@prod2.rightboat.com:/#{Rails.root}/public/`
  end
end
