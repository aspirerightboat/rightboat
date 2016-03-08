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
  desc 'Setup monitrc for solr process'
  task :setup do
    on roles(:db) do
      conf = template('solr.monitrc.haml', solr_cmd: fetch(:solr_cmd))
      upload! StringIO.new(conf), "#{shared_path}/monit/solr.monitrc"
    end
  end

  %w[start stop restart].each do |command|
    desc "#{command} solr"
    task command do
      on roles(:db) do
        within release_path do
          execute :sudo, "monit #{command} solr_rightboat"
        end
      end
    end
  end

  desc 'reindex the whole solr database'
  task :reindex do
    invoke 'solr:stop'
    on roles(:db) do
      execute :rm, "-rf #{fetch :solr_data_path}"
    end
    invoke 'solr:start'
    on roles(:db) do
      within current_path do
        with rails_env: fetch(:rails_env, 'production') do
          info 'Reindexing Solr database'
          execute :bundle, 'exec', :rake, 'sunspot:solr:reindex[,,true]'
        end
      end
    end
  end

end
