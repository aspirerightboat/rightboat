class Image < ApplicationRecord

  mount_uploader :file, RawImageUploader

end
