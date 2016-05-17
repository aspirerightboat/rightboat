namespace :boats_zips do
  desc 'Delete old dirs inside zipped_pdf dir'
  week_ago = 1.week.ago

  task :cleanup do
    Dir['public/zipped_pdfs/*'].each do |file|
      if File.mtime(file) < week_ago
        FileUtils.rm_rf(file)
      end
    end
  end
end
