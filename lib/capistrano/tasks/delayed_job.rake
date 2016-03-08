# taken from here: https://github.com/collectiveidea/delayed_job/wiki/Delayed-Job-tasks-for-Capistrano-3

namespace :workers do
  namespace :delayed_job do

    desc 'Setup monitrc for delayed_job process'
    task :setup do
      on roles(:db) do
        conf = template('dj.monitrc.haml', delayed_job_cmd: fetch(:delayed_job_cmd))
        upload! StringIO.new(conf), "#{shared_path}/monit/dj.monitrc"
      end
    end

    desc 'Stop the delayed_job process'
    task :stop do
      on roles(:db) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            execute :sudo, 'monit stop dj_rightboat'
          end
        end
      end
    end

    desc 'Start the delayed_job process'
    task :start do
      on roles(:db) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            execute :sudo, 'monit start dj_rightboat'
          end
        end
      end
    end


    desc 'Restart the delayed_job process'
    task :restart do
      on roles(:db) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            execute :sudo, 'monit restart dj_rightboat'
          end
        end
      end
    end

  end
end
