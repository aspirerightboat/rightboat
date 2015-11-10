class UserInformation < ActiveRecord::Base

  GENDERS = %w(male female)

  belongs_to :user, inverse_of: :information

  validates_inclusion_of :gender, in: GENDERS, unless: 'gender.blank?'
end
