require 'open-uri'

class BoatImage < ActiveRecord::Base
  belongs_to :boat

  mount_uploader :file, BoatImageUploader

  def update_image_from_source
    return if ENV['SKIP_DOWNLOAD_IMAGES']

    retries = 0
    url = URI.encode(URI.decode(source_url)).gsub('[', '%5B').gsub(']', '%5D')
    uri = (URI.parse(url) rescue nil)
    return unless uri

    begin
      headers = {}
      headers['If-Modified-Since'] = http_last_modified.httpdate if http_last_modified
      headers['If-None-Match'] = http_etag if http_etag
      open(uri, headers) do |f|
        temp_file = Tempfile.new('rb-import-img-')
        temp_file.binmode
        temp_file.write(f.read)
        temp_file.flush

        self.file = ActionDispatch::Http::UploadedFile.new(
            tempfile: temp_file,
            filename: File.basename(uri.path)
        )
        self.content_type = FileMagic.new(FileMagic::MAGIC_MIME).file(temp_file.path).split(';').first
        self.http_last_modified = Time.parse(f.meta['last-modified']) if f.meta['last-modified']
        self.http_etag = f.meta['etag'] if f.meta['etag']
        self.downloaded_at = Time.current
        # puts "[#{id}] - OK" if !Rails.env.production?
      end
    rescue Errno::ECONNREFUSED, Net::ReadTimeout => e
      if retries > 3
        logger.error "#{e.class.name}: #{e.message}. Max retries reached for #{url}"
      else
        retries += 1
        # puts "[#{id}] Retry #{retries}" if !Rails.env.production?
        sleep 3.seconds
        retry
      end
    rescue OpenURI::HTTPError => e
      case e.message[0,3]
        when '404'
          # puts "[#{id}] 404 - Not found, destroy" if !Rails.env.production?
          remove_file!
          destroy(:force) if persisted?
        when '304'
          # puts "[#{id}] 304 - Not modified, continue" if !Rails.env.production?
        else
          logger.error "[#{id}] #{url} #{e.message}"
      end
    end
  end

  def file_exists?
    file.file.present?
  end

  # def mime_type_by_ext
  #   MIME::Types.type_for(file.file.filename).first.content_type
  # end
end
