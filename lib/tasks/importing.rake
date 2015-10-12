namespace :import do

  desc "Run importing job specified by id"
  task :run, [:id] => :environment do |_, args|
    job = Import.find(args.id)

    unless job.running?(false)
      job.update_column :pid, Process.pid
      job.source_class.new(job).run if job.active?
    end
  end

  desc "Run importing eyb members and create import"
  task :eyb_members => :environment do
    Rightboat::Imports::EybMembers.new.run
  end
end
