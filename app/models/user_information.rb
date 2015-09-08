class UserInformation < ActiveRecord::Base
  belongs_to :user, inverse_of: :information
end
