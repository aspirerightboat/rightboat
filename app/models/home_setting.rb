class HomeSetting < ActiveRecord::Base
  mount_uploader :attached_media, HomeImageUploader
end
