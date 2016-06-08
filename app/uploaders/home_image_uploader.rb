class HomeImageUploader < ImageUploader
  def store_dir
    "home_images/#{model.id}"
  end
end
