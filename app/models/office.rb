class Office < ActiveRecord::Base
  include BoatOwner

  belongs_to :user

  has_one :address, as: :addressible, dependent: :destroy

  accepts_nested_attributes_for :address

  validates_presence_of :user_id
  # validates_uniqueness_of :name, scope: :user_id

  before_save :ensure_address

  START_WITH_TITLE = /^#{User::TITLES.join('|')} /i

  def contact_name_parts
    return if contact_name.blank?

    if contact_name =~ START_WITH_TITLE
      contact_name.split(' ', 3)
    else
      [nil, *contact_name.split(' ', 2)]
    end
  end

  def to_s
    name
  end

  private

  def ensure_address
    build_address if !address
  end
end
