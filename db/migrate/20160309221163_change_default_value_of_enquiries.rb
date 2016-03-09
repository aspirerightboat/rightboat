class ChangeDefaultValueOfEnquiries < ActiveRecord::Migration
  def change
    change_column :enquiries, :boat_currency_rate, :float, default: 1
  end
end
