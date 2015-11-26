namespace :deploy do
  before :updated, :setup_solr_data_dir do
    on roles(:import) do
      unless test "[ -d #{fetch :solr_data_path} ]"
        execute :mkdir, "-p #{fetch :solr_data_path}"
      end
    end
  end
end

namespace :solr do
  %w[start stop restart].each do |command|
    desc "#{command} solr"
    task command do
      on roles(:import) do
        within current_path do
          if fetch(:rails_env, '').to_s == 'staging'
            def solr_cmd(cmd)
              execute :bundle, 'exec', 'sunspot-solr', cmd,
                      "--port=8983 --solr-home=#{release_path}/solr --data-directory=#{shared_path}/solr/data --pid-dir=#{shared_path}/pids"
            end
            start_or_restart = command =~ /start/
            solr_cmd('stop') if start_or_restart and test "[ -f #{shared_path}/pids/sunspot-solr.pid ]"
            cmd = start_or_restart ? 'start' : 'stop'
            solr_cmd(cmd)
          else
            with rails_env: fetch(:rails_env, 'production') do
              execute fetch(:solr_cmd) % {cmd: command}
            end
          end
        end
      end
    end
  end

  # desc 'restart solr'
  # task :restart do
  #   invoke 'solr:stop'
  #   invoke 'solr:start'
  # end

  after 'deploy:finished', 'solr:restart'

  desc 'reindex the whole solr database'
  task :reindex do
    invoke 'solr:stop'
    on roles(:import) do
      execute :rm, "-rf #{fetch :solr_data_path}"
    end
    invoke 'solr:start'
    on roles(:import) do
      within current_path do
        with rails_env: fetch(:rails_env, 'production') do
          info 'Reindexing Solr database'
          execute :bundle, 'exec', :rake, 'sunspot:solr:reindex[,,true]'
        end
      end
    end
  end

end
