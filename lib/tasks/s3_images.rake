namespace :s3_images do

  desc 'Ensure that all BoatImage records have content_type set (should be redundant in future as it is filled on boat image save)'
  task :ensure_content_type do
    BoatImage.where(content_type: nil).each do |bi|
      io = open(bi.file_url)
      f = case io when Tempfile then io when StringIO then Tempfile.new.write(io.string) end
      content_type = bi.mime_type_by_file_content(f.path)
      bi.update_column(:content_type, content_type)
    end
  end

  # helpful aws commands:
  # aws s3api copy-object --copy-source rightboat/boat_images/1/1930/1930999/thumb_4563130_20140203175000444_1_LARGE.jpg --bucket rightboat --key boat_images/1/1930/1930999/thumb_4563130_20140203175000444_1_LARGE.jpg --metadata-directive REPLACE --content-type='image/jpeg'
  # s3cmd ls s3://rightboat/boat_images/0/650/650312/
  # aws s3api head-object --bucket rightboat --key boat_images/1/1800/1800103/thumb_2969242L.jpg
  # curl -s -D - https://d2qh54gyqi6t5f.cloudfront.net/boat_images/1/1951/1951915/4697656_20140429072339402_1_LARGE.jpg -o /dev/null

  desc 'Update content-type header on s3 for all boat images (should be redundant in future as it is assigned on boat image save)'
  task upd_content_type: :environment do
    puts 'process jpg images'
    BoatImage.last.id.step(0, -1000) do |i|
      store_dir = "boat_images/#{i / 1000_000}/#{i / 1000}/"
      opts = "--exclude '*' --include '*.jpg' --recursive --metadata-directive REPLACE --content-type='image/jpeg'"
      cmd = "aws s3 cp s3://rightboat/#{store_dir} s3://rightboat/#{store_dir} #{opts}"
      `#{cmd}`
      print '.'
      puts i if i % 50_000 == 0
    end

    i = 0
    puts 'process png, gif, tiff, bmp and psd images'
    BoatImage.where.not(content_type: 'image/jpeg').each do |bi|
      dir = "boat_images/#{bi.id / 1000_000}/#{bi.id / 1000}/#{bi.id}/"
      opts = "--metadata-directive REPLACE --content-type='#{bi.content_type}'"
      cmd = "aws s3 cp s3://rightboat/#{dir} s3://rightboat/#{dir} #{opts}"
      `#{cmd}`
      print '.'
      i += 1
      puts i if i % 50 == 0
    end

    puts 'finished'
  end

  task fix_extension: :environment do
    BoatImage.where('file LIKE ?', '%.jpg').where.not(content_type: 'image/jpeg').each do |bi|
      case bi.content_type
      when 'image/png' then rename_boat_image(bi, File.basename(bi.file.path).sub('.jpg', '.png')); puts "#{bi.id} => png"
      when 'image/x-ms-bmp' then rename_boat_image(bi, File.basename(bi.file.path).sub('.jpg', '.bmp')); puts "#{bi.id} => bmp"
      when 'application/octet-stream'
        uri = URI.parse(URI.encode(bi.file_url))
        io = open(uri)
        f = case io when Tempfile then io when StringIO then Tempfile.new.write(io.string) end
        mime = bi.mime_type_by_file_content(f.path)
        f.delete
        if mime != 'application/octet-stream'
          bi.update_column(:content_type, mime)
          puts "#{bi.id} => #{mime}"
        end
      end
    end
  end

  def url_to_key_path(url)
    url.sub('https://d2qh54gyqi6t5f.cloudfront.net/', '')
  end

  def rename_boat_image(boat_image, new_file_name)
    io = open(boat_image.file_url)
    f = case io when Tempfile then io when StringIO then Tempfile.new.write(io.string) end
    boat_image.remove_file!
    boat_image.save!
    boat_image.file = ActionDispatch::Http::UploadedFile.new(tempfile: f, filename: new_file_name)
    boat_image.save!
  ensure
    f&.delete
  end

end
