class UpdateBrokerDeals < ActiveRecord::Migration
  def up
    User.companies.find_each do |user|
      user.create_deal
    end
  end
end
