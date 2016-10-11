class ArticleCategory < ApplicationRecord

  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]

  has_many :articles, inverse_of: :category, dependent: :restrict_with_error

end
