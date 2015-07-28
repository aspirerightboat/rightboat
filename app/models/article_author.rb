class ArticleAuthor < ActiveRecord::Base

  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders]

  has_many :articles, inverse_of: :author, dependent: :restrict_with_error

  mount_uploader :photo, AvatarUploader

  validates_presence_of :title, :name, :description

end