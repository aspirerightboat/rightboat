class Invoice < ApplicationRecord
  has_many :leads
  belongs_to :user
end
