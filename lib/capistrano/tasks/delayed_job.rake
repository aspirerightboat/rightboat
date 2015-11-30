# taken from here: https://github.com/collectiveidea/delayed_job/wiki/Delayed-Job-tasks-for-Capistrano-3

namespace :workers do
  namespace :delayed_job do

    def args
      fetch(:delayed_job_args, '')
    end

    def delayed_job_roles
      fetch(:delayed_job_server_role, :import)
    end

    desc 'Setup monitrc for delayed_job process'
    task :setup do
      on roles(delayed_job_roles) do
        upload! StringIO.new(template('dj.monitrc.erb')), "#{shared_path}/dj.monitrc"
      end
    end

    desc 'Stop the delayed_job process'
    task :stop do
      on roles(delayed_job_roles) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            # execute :bundle, :exec, :'bin/delayed_job', :stop
            execute :sudo, 'monit stop dj_rightboat'
          end
        end
      end
    end

    desc 'Start the delayed_job process'
    task :start do
      on roles(delayed_job_roles) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            # execute :bundle, :exec, :'bin/delayed_job', args, :start
            execute :sudo, 'monit start dj_rightboat'
          end
        end
      end
    end


    desc 'Restart the delayed_job process'
    task :restart do
      on roles(delayed_job_roles) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            # execute :bundle, :exec, :'bin/delayed_job', args, :restart
            execute :sudo, 'monit restart dj_rightboat'
          end
        end
      end
    end

  end

end
