class Misspelling < ActiveRecord::Base
  belongs_to :source, polymorphic: true

  validates_presence_of :alias_string, :source
end
