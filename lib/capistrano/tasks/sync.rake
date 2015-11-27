namespace :sync do
  desc 'sync staging db with production db, downloaded to dev machine. You need run "cap production db:pull" before this'
  task :staging_db do
    last_synced_db = `ls -t db/rightboat_*.{sql,bz2} | head -n1`.strip
    last_synced_db_zip = last_synced_db.end_with?('sql') ? `bzip2 #{last_synced_db}` : last_synced_db

    if fetch(:rails_env, '').to_s == 'staging'
      on roles(:db) do
        upload! last_synced_db_zip, "#{shared_path}/tmp/"
        zip_file_name = File.basename(last_synced_db_zip)
        execute "bunzip2 -f #{shared_path}/tmp/#{zip_file_name}"
        sql_file_name = zip_file_name.chomp('.bz2')

        yml_string = capture("cat #{shared_path}/config/database.yml")
        yml = YAML.load(yml_string)['staging']
        username = yml['username']
        password = yml['password']
        database = yml['database']
        sql_file_path = "#{shared_path}/tmp/#{sql_file_name}"
        execute "mysql -u#{username} -p#{password} -D #{database} < #{sql_file_path}"
        execute "rm #{sql_file_path}"
      end
    end
  end

  desc 'sync production images to staging'
  task :staging_images do
    if fetch(:rails_env, '').to_s == 'staging'
      on roles(:db) do
        within shared_path do
          execute :aws, 's3 sync s3://rightboat/boat_images public/boat_images --quiet &'
        end
      end
    end
  end
end
