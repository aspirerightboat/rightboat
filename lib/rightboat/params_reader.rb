module Rightboat
  module ParamsReader

    def read_str(str)
      str.strip if str.present?
    end

    def read_downcase_str(str)
      if (str = read_str(str))
        str.downcase
      end
    end

    def read_id(str)
      case str
      when Numeric then str
      when String then str.to_i if str.strip =~ /\A\d+\z/
      end
    end

    def read_page(num_str)
      if num_str.present?
        num_str.to_i.clamp(1..100_000)
      end
    end

    def read_array(items)
      if items.present?
        case items
        when Array then items
        when String then items.split('-')
        end
      end
    end

    def read_ids(ids_str)
      if (arr = read_array(ids_str))
        arr.map { |id| read_id(id) }.compact.presence
      end
    end

    def read_state_codes(codes_str)
      if (arr = read_array(codes_str))
        arr.grep(String).select { |id| Rightboat::USStates.states_map[id] }.presence
      end
    end

    def read_currency(currency_str)
      if currency_str.present?
        Currency.cached_by_name(currency_str)
      end
    end

    def read_boat_price(price_str)
      if price_str.present?
        price_str.to_i.clamp(Boat::PRICES_RANGE)
      end
    end

    def read_boat_price_gbp(price_str, currency)
      if (price_raw = read_boat_price(price_str))
        Currency.convert(price_raw, currency, Currency.default)
      end
    end

    def read_boat_year(year)
      if year.present?
        year.to_i.clamp(Boat::YEARS_RANGE)
      end
    end

    def read_length_unit(length_unit)
      length_unit.presence_in(Boat::LENGTH_UNITS)
    end

    def read_boat_length(len, len_unit)
      if len.present?
        length_range = len_unit == 'm' ? Boat::M_LENGTHS_RANGE : Boat::FT_LENGTHS_RANGE
        len.to_f.round(2).clamp(length_range)
      end
    end

    def read_boat_length_m(len, len_unit)
      if (len = read_boat_length(len, len_unit))
        len = len.ft_to_m if len_unit == 'ft'
        len.round(2).clamp(Boat::M_LENGTHS_RANGE)
      end
    end

    def read_hash(hash, possible_keys)
      if hash.present? && hash.is_a?(Hash)
        hash.with_indifferent_access.slice(*possible_keys)
      end
    end

    def read_tax_status_hash(hash)
      read_hash(hash, %w(paid unpaid))
    end

    def read_new_used_hash(hash)
      read_hash(hash, %w(new used))
    end

  end
end
