namespace :lock do
  desc 'check lock'
  task :check do
    on roles(:db) do
      if test("[ -f #{shared_path}/cap.lock ]")
        require 'time'
        lock_mtime = Time.parse capture("stat --format '%z' #{shared_path}/cap.lock")
        time_now = Time.parse capture('date')
        time_diff = Time.at(time_now - lock_mtime).utc.strftime('%H:%M:%S')
        deploy_user = capture("cat #{shared_path}/cap.lock").strip
        raise StandardError.new <<~MSG
          \n\n\e[0;31mDeployment is already in progress
          Started #{time_diff} ago by #{deploy_user}
          Run 'cap <stage> lock:release' if previous deploy was terminated\e[0m\n
        MSG
      end
    end
  end

  desc 'create lock'
  task :create do
    on roles(:db) do
      deploy_user = `git config user.name`.strip
      execute "echo '#{deploy_user}' > #{shared_path}/cap.lock"
    end
  end

  desc 'release lock'
  task :release do
    on roles(:db) do
      execute "rm #{shared_path}/cap.lock"
    end
  end
end

before 'deploy:starting', 'lock:check'
after 'lock:check', 'lock:create'
after 'deploy:finished', 'lock:release'
