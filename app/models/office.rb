class Office < ActiveRecord::Base
  belongs_to :user

  has_many :boats, inverse_of: :office, dependent: :nullify
  has_one :address, as: :addressible, dependent: :destroy

  accepts_nested_attributes_for :address, allow_destroy: true

  validates_presence_of :user_id, :name
  validates_uniqueness_of :name, scope: :user_id
end
