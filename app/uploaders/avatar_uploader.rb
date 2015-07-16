class AvatarUploader < ImageUploader
  version :thumb do
    process :resize_and_pad => [150, 150]
  end

  # need default image for missing ones?
  # def default_url
  #   "something.jpg"
  # end
end