class BoatCategory < ActiveRecord::Base
  include AdvancedSolrIndex
  include FixSpelling

  has_many :boats, inverse_of: :category, foreign_key: :category_id, dependent: :restrict_with_error

  # solr_update_association :boats

  validates_presence_of :name
  validates_uniqueness_of :name, allow_blank: true

  searchable do
    string :name
    string :name_ngrme, as: :name_ngrme
  end
  alias_attribute :name_ngrme, :name

  def to_s
    name
  end

end
