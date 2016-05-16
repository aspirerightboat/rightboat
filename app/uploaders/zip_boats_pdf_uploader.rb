class ZipBoatsPdfUploader < CarrierWave::Uploader::Base
  storage(Rails.env.production? ? :fog : :file)

  def store_dir
    "zipped_pdfs/"
  end

end
