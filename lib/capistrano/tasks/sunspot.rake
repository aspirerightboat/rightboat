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
        # if command == 'start' or (test "[ -f #{fetch :solr_pid_path} ]" and test "kill -0 $( cat #{fetch :solr_pid_path} )")
          within current_path do
            with rails_env: fetch(:rails_env, 'production') do
              execute fetch(:solr_cmd) % {cmd: command}
            end
          end
        # end
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
