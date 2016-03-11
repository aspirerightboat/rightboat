module BacktraceHelper

  def human_backtrace(backtrace)
    rails_root =  "#{Rails.root}/"

    backtrace.each do |line|
      str = line.sub(%r{.+/gems/(.+)}) { |_| content_tag(:span, $1, style: 'color: gray') }
      str.sub!(rails_root, '')
      str
    end.join('<br>').html_safe
  end

  def output_debug_hash(hash)
    return if hash.blank?

    hash.map { |k, v| "#{k}: #{v.inspect rescue $!.message}" }.join('<br>').html_safe
  end

end
