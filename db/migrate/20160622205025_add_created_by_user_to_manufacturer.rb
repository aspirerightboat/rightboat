class AddCreatedByUserToManufacturer < ActiveRecord::Migration
  def change
    add_reference :manufacturers, :created_by_user, index: true
    add_reference :models, :created_by_user, index: true
  end
end
