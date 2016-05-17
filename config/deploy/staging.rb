server 'staging.rightboat.com', user: 'ubuntu', roles: %w{web app db import}

set :ssh_options, {keys: ['~/.ssh/StagingKey.pem']}

set :user, 'ubuntu'
set :application, 'rightboat.com'
set :deploy_to, '/home/ubuntu/rightboat.com'
set :branch, ENV['BRANCH'] || 'staging'

set :delayed_job_default_cmd, '/etc/init.d/delayed_job_default %{cmd}'
set :delayed_job_import_images_cmd, '/etc/init.d/delayed_job_import_images %{cmd}'
set :solr_data_path, "#{shared_path}/solr/data"
# set :solr_pid, "#{shared_path}/pids/sunspot-solr.pid"
set :solr_cmd, "/home/ubuntu/.rvm/bin/rvm-shell -c 'cd #{current_path} && RAILS_ENV=staging bundle exec sunspot-solr %{cmd} --port=8983 --solr-home=#{current_path}/solr --data-directory=#{shared_path}/solr/data --pid-dir=#{shared_path}/pids'"

set :linked_dirs, fetch(:linked_dirs) + %w(public/boat_images public/broker_logos public/user
                                           public/buyer_guide public/article_images public/zipped_pdfs)
