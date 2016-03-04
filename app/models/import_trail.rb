class ImportTrail < ActiveRecord::Base
  belongs_to :import

  scope :with_errors,    -> { where.not(error_msg: nil) }
  scope :without_errors, -> { where(error_msg: nil) }
  scope :last_day, -> { where('created_at > ?', 1.day.ago) }

  def duration_time
    time_span = (finished_at || Time.current) - created_at
    Time.at(time_span).utc.strftime('%H:%M:%S')
  end

end
