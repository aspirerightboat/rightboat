class HomeSetting < ApplicationRecord
  mount_uploader :attached_media, HomeImageUploader
end
