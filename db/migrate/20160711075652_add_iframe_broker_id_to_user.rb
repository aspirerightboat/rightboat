class AddIframeBrokerIdToUser < ActiveRecord::Migration
  def change
    add_reference :users, :registered_from_affiliate, index: true
    add_reference :leads, :created_from_affiliate, index: true
  end
end
