class String
  # NBSP = "\u00A0"

  def ensure_utf8!
    encode!(Encoding::UTF_8) if encoding != Encoding::UTF_8
    self
  end

  # this solution is twice faster than gsub(/\s+, ' '/)
  def squeeze_whitespaces!
    self.gsub!(/[\r\n\t\u00A0]/, ' ')
    self.gsub!(/ {2,}/, ' ')
    self
  end

end