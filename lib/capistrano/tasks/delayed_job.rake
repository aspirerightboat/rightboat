# taken from here: https://github.com/collectiveidea/delayed_job/wiki/Delayed-Job-tasks-for-Capistrano-3

namespace :workers do
  namespace :delayed_job do

    desc 'Setup monitrc for delayed_job process'
    task :setup do
      on roles(:db) do
        upload_template 'delayed_job.monitrc', "#{shared_path}/monit/delayed_job.monitrc"
      end
    end

    desc 'Stop the delayed_job process'
    task :stop do
      on roles(:db) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            execute :sudo, 'monit stop delayed_job_default'
            execute :sudo, 'monit stop delayed_job_import_images'
          end
        end
      end
    end

    desc 'Start the delayed_job process'
    task :start do
      on roles(:db) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            execute :sudo, 'monit start delayed_job_default'
            execute :sudo, 'monit start delayed_job_import_images'
          end
        end
      end
    end


    desc 'Restart the delayed_job process'
    task :restart do
      on roles(:db) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            execute :sudo, 'monit restart delayed_job_default'
            execute :sudo, 'monit restart delayed_job_import_images'
          end
        end
      end
    end

  end
end
