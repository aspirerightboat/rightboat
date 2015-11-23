namespace :rb_sitemap do
  desc 'Generate sitemap.xml.gz on import and copy to prod servers'
  task :refresh do
    on roles(:import) do
      within current_path do
        execute :bundle, 'exec', :rake, '-s sitemap:refresh'
        execute "mv #{current_path}/public/sitemap.xml.gz #{shared_path}/public/sitemap.xml.gz"
        execute "scp #{shared_path}/public/sitemap.xml.gz rightboat@prod1.rightboat.com:#{shared_path}/public/"
        execute "scp #{shared_path}/public/sitemap.xml.gz rightboat@prod1.rightboat.com:#{shared_path}/public/"
      end
    end
  end
end

