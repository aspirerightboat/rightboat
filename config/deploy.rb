# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'rightboat_v2'
set :repo_url, 'git@github.com:OxygenCapitalLimited/rightboat.git'

set :deploy_to, '/var/www/rightboat_v2'
set :scm, :git
set :format, :pretty
set :log_level, :debug
set :pty, true
set :linked_files, %w(config/database.yml config/secrets.yml config/application.yml config/smtp.yml)
set :linked_dirs, %w(log tmp/pids tmp/cache tmp/sockets vendor/bundle public/uploads solr/data import_data)

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 3

set :rvm_type, :user
set :rvm_ruby_version, '2.2.3'

namespace :deploy do
  after :check,   :'workers:delayed_job:setup'
  after :restart, :'workers:clockwork:restart'
  after :restart, :'workers:delayed_job:restart'
end

def template(file)
  erb = File.read(File.expand_path("../deploy/templates/#{file}", __FILE__))
  ERB.new(erb).result(binding)
end

