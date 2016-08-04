class UpdateBrokerDeals < ActiveRecord::Migration
  def up
    User.companies.includes(:deal).find_each do |user|
      user.create_deal unless user.deal
    end
  end
end
