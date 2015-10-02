class Invoice < ActiveRecord::Base
  has_many :enquiries
  belongs_to :user
end
