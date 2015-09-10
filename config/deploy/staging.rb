server '52.28.247.128',
  user: 'ubuntu',
  roles: %w{web app db import}

set :ssh_options, {keys: ['~/.ssh/StagingKey.pem']}

set :application, 'rightboat.com'
set :deploy_to, '/home/ubuntu/rightboat.com'
set :log_level, :info
set :branch, ENV['BRANCH'] || 'master'

set :passenger_in_gemfile, false
set :passenger_roles, :app
set :passenger_restart_with_sudo, true
set :passenger_restart_command, 'passenger-config restart-app'

set :keep_releases, 1
