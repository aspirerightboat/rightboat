require 'open-uri'

class BoatImage < ActiveRecord::Base
  belongs_to :boat

  mount_uploader :file, BoatImageUploader

  def update_image_from_source(proxy_url: nil, log_error_proc: nil)
    return if ENV['SKIP_DOWNLOAD_IMAGES']

    retries = 0
    url = URI.encode(URI.decode(source_url)).gsub('[', '%5B').gsub(']', '%5D')
    uri = (URI.parse(url) rescue nil)
    if !uri
      log_error_proc&.call("Invalid image url. #{url}")
      return
    end

    begin
      headers = {}
      headers['If-Modified-Since'] = http_last_modified.httpdate if http_last_modified
      headers['If-None-Match'] = http_etag if http_etag
      headers[:proxy] = proxy_url if proxy_url

      open(uri, headers) do |f|
        self.file = ActionDispatch::Http::UploadedFile.new(
            tempfile: f,
            filename: File.basename(uri.path)
        )
        self.content_type = mime_type_by_file_content(f.path)
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
    rescue OpenURI::HTTPError => e
      case e.message[0,3]
        when '404'
          remove_file!
          destroy(:force) if persisted?
        when '304'
        else
          log_error_proc&.call("#{e.class.name}: #{e.message}. url=#{url}")
      end
    end
  end

  def file_exists?
    file.file.present?
  end

  def mime_type_by_file_content(file_path)
    FileMagic.new(FileMagic::MAGIC_MIME).file(file_path).split(';').first
  end
end
