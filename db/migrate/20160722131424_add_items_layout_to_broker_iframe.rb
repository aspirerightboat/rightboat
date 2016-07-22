class AddItemsLayoutToBrokerIframe < ActiveRecord::Migration
  def change
    add_column :broker_iframes, :items_layout, :string, default: 'thumbnail'
  end
end
