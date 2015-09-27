class BuyerGuide < ActiveRecord::Base

  extend FriendlyId
  friendly_id :manufacturer_model, use: [:slugged, :finders]

  mount_uploader :photo, BuyerGuideUploader
  mount_uploader :thumbnail, BuyerGuideUploader

  belongs_to :author, class_name: 'ArticleAuthor', foreign_key: :article_author_id, inverse_of: :buyer_guides
  belongs_to :manufacturer, inverse_of: :buyer_guides
  belongs_to :model

  validates_presence_of :manufacturer, :model, :body, :short_description, :zcard_desc
  validates_length_of :short_description, maximum: 255

  scope :published, -> { where(published: true) }

  def manufacturer_model
    [manufacturer.to_s, model.to_s].reject(&:blank?).join(' ')
  end

  def title
    "#{manufacturer_model} Boat Buyers Guide"
  end

end
