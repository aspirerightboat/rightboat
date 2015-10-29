namespace :import do
  desc 'Run importing job specified by id'
  task :run, [:id] => :environment do |_, args|
    RunImportJob.new(args.id).perform
  end

  desc 'Run importing eyb members and create import'
  task :eyb_members => :environment do
    Rightboat::Imports::EybMembers.new.run
  end
end
