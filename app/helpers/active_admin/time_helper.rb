module ActiveAdmin::TimeHelper
  def time_ago_with_hint(time)
    ago = distance_of_time_in_words(time, Time.current).sub('about ', '~')
    date = l time, format: :short
    content_tag :abbr, "#{ago} ago", title: date
  end
end