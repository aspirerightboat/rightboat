class Office < ActiveRecord::Base
  include BoatOwner

  belongs_to :user

  has_one :address, as: :addressible, dependent: :destroy

  accepts_nested_attributes_for :address

  validates_presence_of :user_id, :name
  validates_uniqueness_of :name, scope: :user_id

  before_save :ensure_address

  private

  def ensure_address
    build_address if !address
  end
end
