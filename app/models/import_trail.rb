class ImportTrail < ActiveRecord::Base
  belongs_to :import

  scope :with_error,    -> { where(error_msg: nil) }
  scope :with_no_error, -> { where.not(error_msg: nil) }
  scope :today,         -> { where('created_at > ?', Time.now.beginning_of_day) }

  def duration
    time_span = (finished_at || Time.current) - created_at
    Time.at(time_span).utc
  end
end
