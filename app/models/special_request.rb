class SpecialRequest < ActiveRecord::Base

  enum request_type: [:customer_detail, :comment, :boat_year, :loa]

  belongs_to :user
end
