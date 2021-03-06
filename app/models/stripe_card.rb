class StripeCard < ApplicationRecord
  belongs_to :user

  def last_digits
    last4.presence || dynamic_last4
  end
end
