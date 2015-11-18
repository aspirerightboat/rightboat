class BrokerInfo < ActiveRecord::Base
  LEAD_EMAIL_DISTRIBUTIONS = %w(user_and_office user_only office_only)

  belongs_to :user

  mount_uploader :logo, BrokerLogoUploader

  after_save :change_lead_price

  private

  def change_lead_price
    if lead_rate_changed?
      user.enquiries.not_deleted.not_invoiced.each do |lead|
        lead.update_lead_price
      end
    end
  end

end
