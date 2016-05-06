# encoding: utf-8

class ZipBoatsPdfUploader < CarrierWave::Uploader::Base
  storage(Rails.env.production? ? :fog : :file)

  def store_dir
    "zip_pdfs/"
  end

end
