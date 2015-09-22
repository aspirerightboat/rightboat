class RBConfig < ActiveRecord::Base

  validates :key, uniqueness: true

  def self.store
    @@all_configs ||= RBConfig.pluck(:key, :value).each_with_object({}) { |(k, v), h| h[k] = v}
  end
end
