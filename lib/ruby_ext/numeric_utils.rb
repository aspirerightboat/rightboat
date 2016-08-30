class Numeric

  def clamp(min, max)
    self < min ? min : (self > max ? max : self)
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

  def gallons_to_liters
    self * 3.78541178
  end

  def kph_to_knots
    self * 0.5399568
  end

  def mph_to_knots
    self * 0.868976241901
  end

  def pounds_to_kilograms
    self * 0.45359237
  end

  def leave_significant(significant_amount)
    num = round
    digits_count = num.to_s.size
    if digits_count > significant_amount
      num.round(significant_amount - digits_count) # 12345.round(-3) #=> 12000
    else
      num
    end
  end

  def try_skip_fraction
    self_floor = self.floor
    (self == self_floor) ? self_floor : self
  end

end
