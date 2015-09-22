class MarineEnquiry < ActiveRecord::Base

  ENQUIRY_TYPES = ['Insurance', 'Finance', 'Transport', 'Warranty', 'Sell my Boat', 'Berths', 'Charter']

  validates_presence_of :first_name, :last_name, :email, :comments
  validates_inclusion_of :title, within: User::TITLES, allow_blank: true
  validates_inclusion_of :enquiry_type, within: ENQUIRY_TYPES, allow_blank: true
  validates_format_of :email, with: /\A[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}\z/i
end
