require 'open-uri'

class BoatImage < ActiveRecord::Base
  belongs_to :boat, inverse_of: :boat_images

  mount_uploader :file, BoatImageUploader

  default_scope -> { order :position }

  def http_last_modified_string
    if (last_modified = read_attribute(:http_last_modified))
      last_modified.httpdate
    else
      50.years.ago.httpdate
    end
  end

  def cache_file_from_source_url
    retries = 0
    url = URI.encode(URI.decode(source_url.to_s)).gsub('[', '%5B').gsub(']', '%5D')
    uri = URI.parse(url) rescue nil
    if !uri || ENV['SKIP_DOWNLOAD_IMAGES']
      return
    end

    puts "[#{id}] Downloading #{url}" if !Rails.env.production?
    begin
      open(url, 'If-Modified-Since' => http_last_modified_string) do |f|
        _t_file = Tempfile.new('import', encoding: 'binary')
        _t_file.write(f.read)
        _t_file.flush

        self.file = ActionDispatch::Http::UploadedFile.new(
          tempfile: _t_file,
          filename: File.basename(uri.path)
        )

        if f.meta['last-modified']
          self.http_last_modified = Time.parse(f.meta['last-modified'].to_s)
        end
        puts "[#{id}] - OK" if !Rails.env.production?
      end
    rescue Exception => e
      if e.is_a?(Errno::ECONNREFUSED) || e.is_a?(Net::ReadTimeout)
        if retries > 5
          puts "[#{id}] Max retries reached. Failed" if !Rails.env.production?
        else
          retries += 1
          puts "[#{id}] Retry #{retries}" if !Rails.env.production?
          sleep 5
          retry
        end
      elsif e.is_a?(OpenURI::HTTPError)
        case e.message[0,3]
          when '404'
            puts "[#{id}] 404 - Not found, destroy" if !Rails.env.production?
            remove_file!
            destroy if persisted?
          when '304'
            puts "[#{id}] 304 - Not modified, continue" if !Rails.env.production?
          else
            logger.error "[#{id}] #{url} #{e.message}"
        end
      end
    end
  end

  def file_exists?
    file.file.present?
  end
end
