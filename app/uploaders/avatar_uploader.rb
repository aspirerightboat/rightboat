class AvatarUploader < ImageUploader
  version :thumb do
    process :resize_and_pad => [150, 150]
  end
end
