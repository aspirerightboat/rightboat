class LeadTrail < ActiveRecord::Base
  belongs_to :lead, class_name: 'Enquiry'
  belongs_to :user

  scope :pending, -> { where(new_status: 'pending') }
  scope :approved, -> { where(new_status: 'approved') }
  scope :rejected, -> { where(new_status: 'rejected') }
  scope :invoiced, -> { where(new_status: 'invoiced') }
  scope :count_from, ->(status, from) { send(status).where('created_at > ?', from).count }
  scope :count_between, ->(status, from, to) { send(status).where('created_at BETWEEN ? AND ?', from, to).count }
end
