server '52.28.247.128', user: 'ubuntu', roles: %w{web app db import}

set :ssh_options, {keys: ['~/.ssh/StagingKey.pem']}

set :application, 'rightboat.com'
set :deploy_to, '/home/ubuntu/rightboat.com'
set :log_level, :info
set :branch, ENV['BRANCH'] || 'master'

set :passenger_in_gemfile, false
set :passenger_roles, :app
set :restart_with_touch, true
