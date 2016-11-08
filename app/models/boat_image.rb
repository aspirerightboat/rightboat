require 'open-uri'

class BoatImage < ApplicationRecord
  enum kind: {regular: 0, layout: 1, side_view: 2}

  serialize :layout_mark_info, Hash

  belongs_to :boat
  belongs_to :layout_image, class_name: 'BoatImage'

  mount_uploader :file, BoatImageUploader

  def display_name
    caption.presence || "Boat image ##{id}"
  end

  def small_props_hash
    {id: id, mini_url: file_url(:mini), url: file_url, caption: caption}
  end

  def move_between(bi_prev, bi_next, images_relation)
    return if !bi_prev && !bi_next

    prev_pos = bi_prev&.position || 0
    next_pos = bi_next&.position || 0

    if bi_next
      if prev_pos + 1 >= next_pos
        image_ids = images_relation.pluck(:id).drop_while { |bi_id| bi_id != bi_next.id }.select { |bi_id| bi_id != id }
        if image_ids.any?
          diff = [prev_pos - next_pos, 0].max + 10
          BoatImage.where(id: image_ids).update_all(['position = position + ?', diff])
          bi_next.reload
          next_pos = bi_next.position
        end
      end
      self.position = (prev_pos + next_pos) / 2
    else
      self.position = prev_pos + 10
    end
  end

  def update_image_from_source(proxy_with_auth: nil, log_error_proc: nil, force: nil)
    return if ENV['SKIP_DOWNLOAD_IMAGES']

    retries = 0
    url = URI.encode(URI.decode(source_url)).gsub('[', '%5B').gsub(']', '%5D')
    uri = (URI.parse(url) rescue nil)
    if !uri
      log_error_proc&.call("Invalid image url. #{url}")
      return
    end

    # don't allow downloaded files to be created as StringIO. force a tempfile to be created.
    # see: http://stackoverflow.com/questions/10496874/why-does-openuri-treat-files-under-10kb-in-size-as-stringio
    if OpenURI::Buffer.const_defined?('StringMax') && OpenURI::Buffer::StringMax > 0
      OpenURI::Buffer.send :remove_const, 'StringMax'
      OpenURI::Buffer.const_set 'StringMax', 0
    end

    begin
      headers = {}
      headers['If-Modified-Since'] = http_last_modified.httpdate if http_last_modified && !force
      headers['If-None-Match'] = http_etag if http_etag && !force
      headers[:proxy_http_basic_authentication] = proxy_with_auth if proxy_with_auth

      open(uri, headers) do |f|
        unless f.is_a?(Tempfile)
          log_error_proc&.call("Invalid image file. url=#{url}")
          return
        end
        file_content_type = mime_type_by_file_content(f.path)
        filename = File.basename(uri.path)
        filename = fix_file_ext(filename, file_content_type)
        self.content_type = file_content_type
        self.file = ActionDispatch::Http::UploadedFile.new(tempfile: f, filename: filename)
        self.http_last_modified = Time.parse(f.meta['last-modified']) if f.meta['last-modified']
        self.http_etag = f.meta['etag'] if f.meta['etag']
        self.downloaded_at = Time.current
      end
    rescue Errno::ECONNREFUSED, Net::ReadTimeout => e
      if retries > 3
        log_error_proc&.call("Image download max retries reached. url=#{url}")
      else
        retries += 1
        sleep 3.seconds
        retry
      end
    # rescue CarrierWave::IntegrityError => e
    #   if e.message =~ /\AYou are not allowed to upload "(.*)" files/ # when uploading not allowed image types
    #     remove_file!
    #     destroy(:force) if persisted?
    #   else
    #     raise e
    #   end
    rescue OpenURI::HTTPError => e
      case e.message[0,3]
      when '404'
        remove_file!
        destroy(:force) if persisted?
      when '304'
      when '408' # request timeout
        if retries > 3
          log_error_proc&.call("Image download max retries reached. url=#{url}")
        else
          retries += 1
          sleep 3.seconds
          retry
        end
      else
        log_error_proc&.call("#{e.class.name}: #{e.message}. url=#{url}")
      end
    rescue CarrierWave::ProcessingError => e
      log_error_proc&.call("#{e.class.name}: #{e.message}. url=#{url}")
    end
  end

  def file_exists?
    file.file.present?
  end

  GIF_REGEX = /^GIF8/
  PNG_REGEX = /^#{Regexp.new("\x89PNG".force_encoding('binary'))}/
  JPG_REGEX = /^#{Regexp.new("\xff\xd8\xff\xe0\x00\x10JFIF".force_encoding('binary'))}/
  JPG2_REGEX = /^#{Regexp.new("\xff\xd8\xff\xe1(.*){2}Exif".force_encoding('binary'))}/

  # see: http://stackoverflow.com/questions/4600679/detect-mime-type-of-uploaded-file-in-ruby#answer-16635245
  def mime_type_by_file_content(file_path)
    case IO.read(file_path, 10)
    when GIF_REGEX then 'image/gif'
    when PNG_REGEX then 'image/png'
    when JPG_REGEX then 'image/jpeg' # there are cases when filemagic recognizes jpg files with this header as application/octet-stream
    when JPG2_REGEX then 'image/jpeg'
    else FileMagic.new(FileMagic::MAGIC_MIME).file(file_path).split(';').first
    end
  end

  private

  def fix_file_ext(filename, file_content_type)
    extension = File.extname(filename)
    ext_by_file_content = case file_content_type
                          when 'image/jpeg' then '.jpg'
                          when 'image/png' then '.png'
                          when 'image/gif' then '.gif'
                          when 'image/bmp', 'image/x-ms-bmp' then '.bmp'
                          when 'image/tiff' then '.tif'
                          when 'image/vnd.adobe.photoshop' then '.psd'
                          end

    if ext_by_file_content.present? && ext_by_file_content != extension
      filename.gsub!(/\.\w*\z/, '')
      filename << ext_by_file_content
    end

    filename
  end

end
