class Invoice < ActiveRecord::Base
  has_many :leads
  belongs_to :user
end
