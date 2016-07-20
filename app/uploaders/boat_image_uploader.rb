class BoatImageUploader < ImageUploader

  process :store_dimensions
  process :set_content_type

  def store_dir
    i = model.id
    "boat_images/#{i / 1000_000}/#{i / 1000}/#{i}" # generally it is a good idea to not have so many files in one folder (althrough s3 has no files limit in one bucket)
  end

  # def filename
  #   caption = (model.caption.downcase.gsub(/[^a-z0-9]/, ' ').strip.squeeze(' ').split(' ').first(5).gsub(' ', '-') if model.caption.present?).presence || 'img'
  #   "#{caption}.#{model.file.file.extension}" if original_filename
  # end

  version :thumb do
    process :resize_to_fill => [427, 285]
  end

  version :mini do
    process :resize_to_fill => [127, 85]
  end

  private

  def store_dimensions
    if file && model
      safe_file_path = file.path.gsub(/[^\/\w.-]/, '')
      model.width, model.height = `identify -format '%w %h' #{safe_file_path}`.chomp.split(' ')
    end
  end

  def set_content_type
    if file && model
      model.content_type ||= model.mime_type_by_file_content(file.path)
      file.instance_variable_set(:@content_type, model.content_type)
    end
  end

end
