class HomeSetting < ActiveRecord::Base
  mount_uploader :attached_media, AvatarUploader
end
