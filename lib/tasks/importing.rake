namespace :import do

  desc 'Run importing job specified by id'
  task :run, [:id] => :environment do |_, args|
    import = Import.find(args.id)
    if import.active? && !import.running?(false)
      import.source_class.new(import).run
    end
  end

  desc 'Run importing eyb members and create import'
  task :eyb_members => :environment do
    Rightboat::Imports::EybMembers.new.run
  end
end
