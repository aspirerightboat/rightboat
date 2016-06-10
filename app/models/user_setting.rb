class UserSetting < ActiveRecord::Base
  belongs_to :user
  alias_attribute :country, :country_iso
  alias_attribute :currency, :currency_name
end
