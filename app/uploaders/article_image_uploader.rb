class ArticleImageUploader < ImageUploader
  def store_dir
    "rb-assets/article-images/#{model.id}"
  end

  version :main do
    process :resize_to_fill => [1280, 534]
  end

  version :thumb do
    process :resize_to_fill => [350, 234]
  end
end