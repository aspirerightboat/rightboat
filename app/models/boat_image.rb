require 'open-uri'

class BoatImage < ActiveRecord::Base
  belongs_to :boat, inverse_of: :boat_images

  mount_uploader :file, BoatImageUploader

  default_scope -> { order :position }

  validates_presence_of :file, :boat

  def http_last_modified_string
    if (last_modified = read_attribute(:http_last_modified))
      last_modified.httpdate
    else
      50.years.ago.httpdate
    end
  end

  def cache_file_from_source_url
    retries = 0

    begin
      puts "[#{id}] Downloading #{source_url}... #{retries > 0 ? "retry #{retries}" : ''}"
      open(source_url, "If-Modified-Since" => http_last_modified_string) do |f|
        _t_file = Tempfile.new('import', :encoding => 'binary')
        _t_file.write(f.read)
        _t_file.flush

        uri = URI.parse(source_url)
        self.file = ActionDispatch::Http::UploadedFile.new(
          tempfile: _t_file,
          filename: File.basename(uri.path)
        )

        if f.meta['last-modified']
          self.http_last_modified = Time.parse(f.meta['last-modified'].to_s)
        end
      end
    rescue Exception => e
      if e.is_a?(Errno::ECONNREFUSED) || e.is_a?(Net::ReadTimeout)
        if retries > 5
          puts "Max retries reached. Failed"
        else
          retries += 1
          sleep 5
          retry
        end
      elsif e.is_a?(OpenURI::HTTPError)
        case e.message[0,3]
          when "404"
            puts "[#{id}] #{source_url} 404 - destroying image"
            self.destroy if self.persisted?
            self.file = nil
          when "304"
            puts "[#{id}] #{source_url} 304 - not modified, continuing"
          else
            Rails.logger.error "[#{id}] #{source_url} #{e.message}"
        end
      end

    end
  end

end
