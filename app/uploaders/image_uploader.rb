class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick

  storage(Rails.env.production? ? :fog : :file)

  def store_dir
    "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_white_list
    %w(jpg jpeg gif png bmp)
  end
end
