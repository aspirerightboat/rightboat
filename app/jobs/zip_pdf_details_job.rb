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
      LeadsMailer.lead_created_notify_buyer(enquiry.id).deliver_now
      broker = enquiry.boat.user
        if %w(nick@popsells.com).include? broker.email
          LeadsMailer.lead_created_notify_pop_yachts(enquiry.id).deliver_later
        elsif broker.payment_method_present?
          LeadsMailer.lead_created_notify_broker(enquiry.id).deliver_later
        else
          LeadsMailer.lead_created_tease_broker(enquiry.id).deliver_later
        end
    end

    zipfile_name = "#{Rails.root}/boat_pdfs/#{Time.current.strftime('%Y-%m-%d')}/#{job.id}-rightboat.zip"
    if system("zip -j #{zipfile_name} #{files.join(' ')}")
      uploader = ZipBoatsPdfUploader.new
      uploader.store!(File.new(zipfile_name))
      job.update(url: uploader.url, status: :ready)
    end
  end
end
