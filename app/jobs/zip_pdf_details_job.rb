class ZipPdfDetailsJob
  attr_accessor :boats, :job, :enquiries, :files

  def initialize(job:, enquiries: ,boats:)
    @job = job
    @boats = boats
    @enquiries = enquiries
  end

  def perform
    files = []

    enquiries.each do |enquiry|
      files << Rightboat::BoatPdfGenerator.ensure_pdf(enquiry.boat)
      broker = enquiry.boat.user
        if %w(nick@popsells.com).include? broker.email
          LeadsMailer.lead_created_notify_pop_yachts(enquiry.id).deliver_later
        elsif broker.payment_method_present?
          LeadsMailer.lead_created_notify_broker(enquiry.id).deliver_later
        else
          LeadsMailer.lead_created_tease_broker(enquiry.id).deliver_later
        end
    end

    zipfile_name = "#{Rails.root}/boat_pdfs/#{Time.current.strftime('%Y-%m-%d')}/#{generate_filename}"
    if system("zip -j '#{zipfile_name}' #{files.join(' ')}")
      uploader = ZipBoatsPdfUploader.new
      uploader.store!(File.new(zipfile_name))
      job.update(url: uploader.url, status: :ready)

      LeadsMailer.leads_created_notify_buyer(enquiries, zipfile_name).deliver_now
    end
  end

  private

  def generate_filename
    # Rightboat-59 - Sunseeker 58 and Jeanneau GH78 and Azimuth 48 and other
    prefix = "Rightboat-#{job.id}"

    name = case boats.count
      when 0
        "#{prefix}.zip"
      when 1
        "#{prefix} - #{boats.first.manufacturer} #{boats.first.model}.zip"
      when 2
        "#{prefix} - #{boats.first.manufacturer} #{boats.first.model} and #{boats.last.manufacturer} #{boats.last.model}.zip"
      else
        "#{prefix} - #{boats.first.manufacturer} #{boats.first.model} and #{boats.last.manufacturer} #{boats.last.model} and other.zip"
    end
    name.gsub(/[^\w .-]/, '').squeeze(' ').strip
  end
end
