class AddEmailSentAtColumnToMailClicks < ActiveRecord::Migration
  def change
    add_column :mail_clicks, :email_sent_at, :datetime
  end
end
