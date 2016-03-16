class Misspelling < ActiveRecord::Base

  attr_accessor :source_name

  belongs_to :source, polymorphic: true
  belongs_to :model, -> { where(misspellings: {source_type: 'Model'}) }, foreign_key: 'source_id'

  validates_presence_of :alias_string, :source
end
