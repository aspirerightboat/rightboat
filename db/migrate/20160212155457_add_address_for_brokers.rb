class AddAddressForBrokers < ActiveRecord::Migration
  def up
    User.companies.includes(:address).to_a.select { |u| !u.address }.each { |u| u.address = Address.new; u.save! }
  end
end
