namespace :monit do
  task :setup do
    on roles(:db) do
      execute :mkdir, "-p #{shared_path}/monit"
    end
  end

  desc 'Reload monitrc config'
  task :reload do
    on roles(:db) do
      execute :sudo, 'service monit reload'
    end
  end
end