namespace :rb_sitemap do
  desc 'Create sitemap.xml.gz on import server and copy to prod servers'
  task :refresh do
    `bundle exec rake -s sitemap:refresh`
    current_xml_path = '/opt/applications/rightboat.com/current/public/sitemap.xml.gz'
    shared_xml_path = '/opt/applications/rightboat.com/shared/public/sitemap.xml.gz'
    `mv  #{current_xml_path} #{shared_xml_path}`
    `scp #{shared_xml_path} rightboat@prod1.rightboat.com:/#{shared_xml_path}`
    `scp #{shared_xml_path} rightboat@prod2.rightboat.com:/#{shared_xml_path}`
  end
end
