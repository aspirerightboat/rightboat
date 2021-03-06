# config valid only for current version of Capistrano
lock '3.6.1'

set :application, 'rightboat_v2'
set :repo_url, 'git@github.com:OxygenCapitalLimited/rightboat.git'

set :deploy_to, '/var/www/rightboat_v2'
set :linked_files, %w(config/database.yml config/secrets.yml config/application.yml config/smtp.yml public/sitemap.xml.gz public/robots.txt)
set :linked_dirs, %w(log tmp/pids tmp/cache tmp/sockets vendor/bundle
                     public/uploads public/exports solr import_data boat_pdfs internal_data)

set :scm, :git
set :branch, ENV['BRANCH'] || 'master'

set :log_level, :info
set :keep_releases, 3

set :rvm_type, :user
set :rvm_ruby_version, '2.3.0'

# see: https://github.com/sgruhier/capistrano-db-tasks
# bundle exec cap production db:pull  <- saves production db to local db
require 'capistrano-db-tasks'
# if you haven't already specified
#set :rails_env, "production"
# if you want to remove the local dump file after loading
set :db_local_clean, false
# if you want to remove the dump file from the server after downloading
set :db_remote_clean, true
# if you want to exclude table from dump
#set :db_ignore_tables, []
# if you want to exclude table data (but not table schema) from dump
#set :db_ignore_data_tables, []
# If you want to import assets, you can change default asset dir (default = system)
# This directory must be in your shared directory on the server
#set :assets_dir, %w(public/assets public/att)
#set :local_assets_dir, %w(public/assets public/att)
# if you want to work on a specific local environment (default = ENV['RAILS_ENV'] || 'development')
#set :locals_rails_env, "production"
# if you are highly paranoid and want to prevent any push operation to the server
set :disallow_pushing, true
# if you prefer bzip2/unbzip2 instead of gzip
#set :compressor, :bzip2

namespace :deploy do
  # after :check,   'monit:setup'
  # after :check,   'solr:setup'
  # after :check,   'workers:delayed_job:setup'
  after :check,   'workers:delayed_job:stop'
  # after :restart, 'monit:reload'
  after :restart, 'workers:delayed_job:start'
  after :restart, 'solr:restart'
end

def upload_template(template_name, upload_to)
  content = File.read(File.expand_path("../deploy/templates/#{template_name}.erb", __FILE__))
  res = ERB.new(content).result(binding)
  upload! StringIO.new(res), upload_to
end
