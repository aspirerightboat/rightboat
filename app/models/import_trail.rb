class ImportTrail < ActiveRecord::Base
  belongs_to :import

  scope :with_errors,    -> { where(error_msg: nil) }
  scope :without_errors, -> { where.not(error_msg: nil) }
  scope :last_day, -> { where('created_at > ?', 1.day.ago) }

  def duration
    time_span = (finished_at || Time.current) - created_at
    Time.at(time_span).utc
  end
end
