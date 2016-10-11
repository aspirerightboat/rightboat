class Article < ApplicationRecord

  extend FriendlyId
  friendly_id :title, use: [:slugged, :finders]

  belongs_to :category,
             class_name: 'ArticleCategory',
             foreign_key: :article_category_id,
             counter_cache: true,
             inverse_of: :articles

  belongs_to :author,
             class_name: 'ArticleAuthor',
             counter_cache: true,
             foreign_key: :article_author_id,
             inverse_of: :articles

  mount_uploader :image, ArticleImageUploader

  default_scope -> { order(created_at: :desc) }

  def ts_str
    created_at.strftime("#{created_at.day.ordinalize} %b %Y")
  end

end
