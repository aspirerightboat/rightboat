module BacktraceHelper

  def human_backtrace(backtrace)
    rails_root = Rails.root.to_s
    shared_dir = rails_root.sub(%r{releases/\d+}, 'shared')

    backtrace.map do |line|
      case
      when line[shared_dir] then content_tag(:span, line.sub(shared_dir, 'SHARED_DIR'), style: 'color: gray')
      when line[rails_root] then line.sub(rails_root, 'RAILS_ROOT')
      else line
      end
    end.join('<br>').html_safe
  end

  def output_debug_hash(hash)
    return if hash.blank?

    hash.map { |k, v| "#{k}: #{v.inspect rescue $!.message}" }.join('<br>').html_safe
  end

end
