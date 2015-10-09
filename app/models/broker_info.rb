class BrokerInfo < ActiveRecord::Base
  belongs_to :user

  mount_uploader :logo, BrokerLogoUploader
end
