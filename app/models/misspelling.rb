class Misspelling < ActiveRecord::Base

  attr_accessor :source_name

  belongs_to :source, polymorphic: true

  validates_presence_of :alias_string, :source
end
