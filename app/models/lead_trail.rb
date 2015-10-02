class LeadTrail < ActiveRecord::Base
  belongs_to :lead, class_name: 'Enquiry'
  belongs_to :user
end
