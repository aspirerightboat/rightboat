class ImportTrail < ActiveRecord::Base
  belongs_to :import

  def duration
    time_span = (finished_at || Time.current) - created_at
    Time.at(time_span).utc
  end
end
