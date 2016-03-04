namespace :export do

  desc 'Run export job'
  task :run, [:id] => :environment do |_t, args|
    Export.find(args.id).run!
  end

  desc 'Run all export jobs'
  task run_all: :environment do
    Export.run_all!
  end

end
