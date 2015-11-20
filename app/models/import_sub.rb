class ImportSub < ActiveRecord::Base # Import Substitution
  belongs_to :import

  def fixed_from
    use_regex? ? Regexp.new(from) : from
  end

  def process_text!(txt)
    txt.gsub!(fixed_from, to)
  end

  def processed_sample
    sample_text.gsub(fixed_from, to)
  end
end
