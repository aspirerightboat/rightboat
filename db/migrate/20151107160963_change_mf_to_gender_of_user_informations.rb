class ChangeMfToGenderOfUserInformations < ActiveRecord::Migration
  def change
    rename_column :user_informations, :mf, :gender
  end
end
