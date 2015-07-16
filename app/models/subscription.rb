class Subscription < ActiveRecord::Base

  has_and_belongs_to_many :users

  validates_presence_of :name
  validates_presence_of :description
  validates_uniqueness_of :name, allow_blank: true

end
