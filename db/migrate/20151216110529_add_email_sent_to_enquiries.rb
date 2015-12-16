class AddEmailSentToEnquiries< ActiveRecord::Migration
  def change
    add_column :enquiries, :email_sent, :boolean, default: false
  end
end
