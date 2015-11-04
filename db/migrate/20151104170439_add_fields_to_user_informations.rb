class AddFieldsToUserInformations < ActiveRecord::Migration
  def change
    add_column :user_informations, :about_me, :text
    add_column :user_informations, :mf, :string
    add_column :user_informations, :dob, :date
    add_column :user_informations, :sail_power, :string
    add_column :user_informations, :boater_type, :string
    add_column :user_informations, :boating_place, :string
    add_column :user_informations, :have_boat, :boolean, default: false
    add_column :user_informations, :boat_type, :string
    rename_column :user_informations, :looking_for_berth, :require_berth
  end
end
