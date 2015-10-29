namespace :workers do
  namespace :clockwork do
    task :stop do
      on roles(:import) do
        within current_path do
          with rails_env: fetch(:rails_env) do
            execute :bundle, :exec, :clockworkd, "-c clock.rb --pid-dir=#{cw_pid_dir} --dir=#{current_path} --log-dir=#{cw_log_dir} stop"
          end
        end
      end
    end

    task :status do
      on roles(:import) do
        within current_path do
          with rails_env: fetch(:rails_env) do
            execute :bundle, :exec, :clockworkd, "-c clock.rb --pid-dir=#{cw_pid_dir} --dir=#{current_path} --log-dir=#{cw_log_dir} status"
          end
        end
      end
    end

    task :start do
      on roles(:import) do
        within current_path do
          with rails_env: fetch(:rails_env) do
            execute :bundle, :exec, :clockworkd, "-c clock.rb --pid-dir=#{cw_pid_dir} --dir=#{current_path} --log-dir=#{cw_log_dir} -m start"
          end
        end
      end
    end

    task :restart do
      invoke 'workers:clockwork:stop'
      invoke 'workers:clockwork:start'
    end

    def cw_log_dir; "#{shared_path}/log" end
    def cw_pid_dir; "#{shared_path}/tmp/pids" end
  end

end
