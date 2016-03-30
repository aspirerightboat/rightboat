namespace :boat_pdfs do
  desc 'Delete old dirs inside boat_pdf dir'
  task :cleanup do
    week_ago = 1.week.ago

    Dir['boat_pdfs/*'].each do |dir|
      if File.mtime(dir) < week_ago
        FileUtils.rm_rf(dir)
      end
    end
  end
end
