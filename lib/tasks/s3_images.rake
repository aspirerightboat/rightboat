namespace :s3_images do

  desc 'Ensure that all BoatImage records have content_type set (should be redundant in future as it is filled on boat image save)'
  task :ensure_content_type do
    # don't allow downloaded files to be created as StringIO. force a tempfile to be created.
    if OpenURI::Buffer.const_defined?('StringMax') && OpenURI::Buffer::StringMax > 0
      OpenURI::Buffer.send :remove_const, 'StringMax'
      OpenURI::Buffer.const_set 'StringMax', 0
    end

    BoatImage.where(content_type: nil).each do |bi|
      tmp_file_path = open(bi.file_url(:mini)).path
      content_type = bi.mime_type_by_file_content(tmp_file_path)
      bi.update_column(:content_type, content_type)
    end
  end

  desc 'Update content-type header on s3 for all boat images (should be redundant in future as it is assigned on boat image save)'
  task upd_content_type: :environment do
    i = 0
    puts 'started'
    BoatImage.where('id > 11550').find_each do |bi|
      [bi.file.url, bi.file.url(:thumb), bi.file.url(:mini)].each do |url|
        path = url.sub('https://d2qh54gyqi6t5f.cloudfront.net/', '')
        cmd = "aws s3api copy-object --copy-source rightboat/#{path}"
        cmd << " --bucket rightboat --key #{path} --metadata-directive REPLACE"
        cmd << " --content-type='#{bi.content_type}'"
        r = `#{cmd}`
        if r.start_with?('{')
          print '.'
        else
          print 'x'
        end
      end

      i += 1
      if i % 100_000 == 0
        puts "processed #{i} images"
      end
      puts bi.id if i % 25 == 0
    end
  end

end
