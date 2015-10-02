class CreateBrokerInfosForUsers < ActiveRecord::Migration
  def up
    User.companies.pluck(:id).each do |user_id|
      BrokerInfo.find_or_create_by(user_id: user_id)
    end
  end
end
