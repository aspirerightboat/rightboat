class MailClick < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :user_id, :url, :action_fullname, :email_sent_at
  validates_uniqueness_of :url, scope: [:user_id, :action_fullname, :email_sent_at]
end
