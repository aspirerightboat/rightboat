class RemoveSecurePaymentFromBoat < ActiveRecord::Migration
  def change
    remove_column :boats, :secure_payment
  end
end
