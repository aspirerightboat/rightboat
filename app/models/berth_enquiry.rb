class BerthEnquiry < ActiveRecord::Base

  belongs_to :user, inverse_of: :berth_enquiries
end
