class SpecialRequest < ActiveRecord::Base

  enum request_type: {customer_detail: 0, comment: 1, boat_year: 2, loa: 3}

  belongs_to :user
end
