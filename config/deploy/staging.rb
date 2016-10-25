server 'staging.rightboat.com', user: 'ubuntu', roles: %w{web app db import}

set :user, 'ubuntu'
set :application, 'rightboat.com'
set :deploy_to, '/home/ubuntu/rightboat.com'
set :branch, ENV['BRANCH'] || 'staging'

set :delayed_job_default_cmd, '/etc/init.d/delayed_job_default %{cmd}'
set :delayed_job_import_images_cmd, '/etc/init.d/delayed_job_import_images %{cmd}'
set :solr_data_path, "#{shared_path}/solr/staging/data"
set :solr_process_regexp, 'java -server .*solr.*'
set :solr_cmd, '/etc/init.d/solr %{cmd}'

set :linked_dirs, fetch(:linked_dirs) + %w(public/boat_images public/broker_logos public/user
                                           public/buyer_guide public/article_images public/manufacturer_logos)
