class LeadTrail < ActiveRecord::Base
  belongs_to :lead
  belongs_to :user

  delegate :bad_quality_reason, :bad_quality_comment, to: :lead

  scope :pending, -> { where(new_status: 'pending') }
  scope :approved, -> { where(new_status: 'approved') }
  scope :rejected, -> { where(new_status: 'rejected') }
  scope :invoiced, -> { where(new_status: 'invoiced') }

  def comments
    ret = ''
    if new_status == 'rejected'
      ret += "#{lead.bad_quality_reason.humanize}: " if lead.bad_quality_reason
      ret += lead.bad_quality_comment if lead.bad_quality_comment
    elsif new_status == 'deleted'
      ret += lead.bad_quality_comment if lead.bad_quality_comment
    end
    ret
  end
end
