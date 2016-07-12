class AddTokenIndexToBrokerIframe < ActiveRecord::Migration
  def change
    add_index :broker_iframes, :token
  end
end
