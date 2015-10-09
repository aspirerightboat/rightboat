class AddFieldsToBrokerInfo < ActiveRecord::Migration
  def change
    # add_column :broker_infos, :company_name, :string
    add_column :broker_infos, :website, :string
    add_column :broker_infos, :description, :text
    add_column :broker_infos, :email, :string
    add_column :broker_infos, :additional_email, :string
    add_column :broker_infos, :contact_name, :string
    add_column :broker_infos, :position, :string
    add_column :broker_infos, :vat_number, :string
    add_column :broker_infos, :logo, :string
    add_column :broker_infos, :copy_to_head_office, :boolean, default: true
    # remove_column :users, :company_name
    remove_column :users, :company_weburl
    remove_column :users, :company_description
  end
end
