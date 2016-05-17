namespace :boats_zips do
  desc 'Delete old dirs inside zipped_pdf dir'
  task :cleanup do
    Dir['public/zipped_pdfs/*'].each do |file|
      FileUtils.rm_rf(file)
    end
  end
end
