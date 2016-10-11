class ArticleAuthor < ApplicationRecord

  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]

  has_many :articles, inverse_of: :author, dependent: :restrict_with_error
  has_many :buyer_guides, inverse_of: :author, dependent: :destroy

  mount_uploader :photo, AvatarUploader

  validates_presence_of :title, :name, :description

end
