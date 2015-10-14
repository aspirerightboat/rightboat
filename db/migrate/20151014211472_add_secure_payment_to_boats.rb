class AddSecurePaymentToBoats < ActiveRecord::Migration
  def change
    add_column :boats, :secure_payment, :boolean, default: false
  end
end
