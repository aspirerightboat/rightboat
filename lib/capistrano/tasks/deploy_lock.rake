# extracted from caplock gem, see: https://github.com/Druwerd/caplock/blob/master/lib/caplock.rb

namespace :lock do
  desc 'check lock'
  task :check do
    on roles(:db) do
      lock_exists = capture("if [ -e #{shared_path}/cap.lock ]; then echo 'true'; fi").strip == 'true'

      if lock_exists
        raise StandardError.new("\n\n\e[0;31m A Deployment is already in progress\n Remove #{shared_path}/cap.lock to unlock\e[0m\n\n")
      end
    end
  end

  desc 'create lock'
  task :create do
    on roles(:db) do
      execute "touch #{shared_path}/cap.lock"
    end
  end

  desc 'release lock'
  task :release do
    on roles(:db) do
      execute "rm -f #{shared_path}/cap.lock"
    end
  end
end

before 'deploy:starting', 'lock:check'
after 'lock:check', 'lock:create'
after 'deploy:finished', 'lock:release'
