module Rightboat
  class Unit
    LENGTH_RATES = {
        'm' => 1,
        'ft' => 3.28084,
    }

    def self.convert_length(value, unit_from, unit_to)
      return unless value
      return value if unit_from == unit_to

      value * (LENGTH_RATES[unit_to] / LENGTH_RATES[unit_from])
    end
  end
end
