class Numeric
  def percents
    (self * 100).round
  end

  def ft_to_m
    self * 0.3048
  end

  def m_to_ft
    self / 0.3048
  end

  def inch_to_m
    self * 0.0254
  end

  def clamp(min, max)
    self < min ? min : (self > max ? max : self)
  end
end