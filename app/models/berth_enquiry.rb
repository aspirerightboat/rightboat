class BerthEnquiry < ApplicationRecord

  belongs_to :user, inverse_of: :berth_enquiries
end
