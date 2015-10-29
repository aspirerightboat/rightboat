server 'staging.rightboat.com', user: 'ubuntu', roles: %w{web app db import}

set :ssh_options, {keys: ['~/.ssh/StagingKey.pem']}

set :application, 'rightboat.com'
set :deploy_to, '/home/ubuntu/rightboat.com'
set :log_level, :info
set :branch, ENV['BRANCH'] || 'master'
