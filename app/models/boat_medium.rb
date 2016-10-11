class BoatMedium < ApplicationRecord
  
  belongs_to :boat

  scope :virtual_tour, -> { where(attachment_title: 'Virtual Tour') }
end
