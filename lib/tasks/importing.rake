namespace :import do
  desc 'Run importing job specified by id'
  task :run, [:id, :manual] => :environment do |_, args|
    Import.find(args.id).try_run_import!(args.manual == 'manual')
  end

  desc 'Run importing eyb members and create import'
  task :eyb_members => :environment do
    Rightboat::Imports::EybMembers.new.run
  end

  desc 'Download BoatStream feed from sftp and save in import_data/boat_stream.xml'
  task :download_boatstream_feed do
    local_file = 'import_data/boat_stream.xml'

    if File.mtime(local_file) < 1.day.ago
      sftp = 'sshpass -e sftp -oBatchMode=no -b - rightboats@elba.boats.com'
      listing = `echo 'ls -l upload/*.xml' | #{sftp} | grep -v "sftp>"`.strip # they restricted ls params so we cannot just sort by time "ls -t"
      # -rw-r--r--    0 3011     500      76092888 Feb 14 04:03 upload/BS_dbe29940-ea8e-4399-9804-0b4417e9620b188500188505.xml
      remote_file = listing.scan(/(\w\w\w (?: |\d)\d \d\d:\d\d) (\S+)$/).map { |t, f| [Time.parse(t), f] }.max_by(&:first).last

      `echo "get -P #{remote_file} #{local_file}" | #{sftp}`

      ExpertMailer.download_feed_error('BoatStream').deliver_now if File.mtime(local_file) < 1.day.ago
    end
  end

end
