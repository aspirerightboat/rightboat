module TimeHelper
  def smart_date(time)
    format_str = time.year == Time.current.year ? '%d %b' : '%d %b %Y'
    time.strftime(format_str)
  end
end
