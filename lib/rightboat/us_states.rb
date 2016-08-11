module Rightboat
  class USStates
    def self.states_map
      @states_map ||= {
          'AL' => 'Alabama',
          'AK' => 'Alaska',
          'AZ' => 'Arizona',
          'AR' => 'Arkansas',
          'CA' => 'California',
          'CO' => 'Colorado',
          'CT' => 'Connecticut',
          'DE' => 'Delaware',
          'FL' => 'Florida',
          'GA' => 'Georgia',
          'HI' => 'Hawaii',
          'ID' => 'Idaho',
          'IL' => 'Illinois',
          'IN' => 'Indiana',
          'IA' => 'Iowa',
          'KS' => 'Kansas',
          'KY' => 'Kentucky',
          'LA' => 'Louisiana',
          'ME' => 'Maine',
          'MD' => 'Maryland',
          'MA' => 'Massachusetts',
          'MI' => 'Michigan',
          'MN' => 'Minnesota',
          'MS' => 'Mississippi',
          'MO' => 'Missouri',
          'MT' => 'Montana',
          'NE' => 'Nebraska',
          'NV' => 'Nevada',
          'NH' => 'New Hampshire',
          'NJ' => 'New Jersey',
          'NM' => 'New Mexico',
          'NY' => 'New York',
          'NC' => 'North Carolina',
          'ND' => 'North Dakota',
          'OH' => 'Ohio',
          'OK' => 'Oklahoma',
          'OR' => 'Oregon',
          'PA' => 'Pennsylvania',
          'RI' => 'Rhode Island',
          'SC' => 'South Carolina',
          'SD' => 'South Dakota',
          'TN' => 'Tennessee',
          'TX' => 'Texas',
          'UT' => 'Utah',
          'VT' => 'Vermont',
          'VA' => 'Virginia',
          'WA' => 'Washington',
          'WV' => 'West Virginia',
          'WI' => 'Wisconsin',
          'WY' => 'Wyoming',
      }
    end

    def self.biggest_cities
      @biggest_cities = {
          'AL' => ['Montgomery', 'Birmingham'],
          'AK' => ['Juneau', 'Anchorage'],
          'AZ' => ['Phoenix'],
          'AR' => ['Little Rock'],
          'CA' => ['Sacramento', 'Los Angeles'],
          'CO' => ['Denver'],
          'CT' => ['Hartford', 'Bridgeport'],
          'DE' => ['Dover', 'Wilmington'],
          'FL' => ['Tallahassee', 'Jacksonville'],
          'GA' => ['Atlanta'],
          'HI' => ['Honolulu'],
          'ID' => ['Boise'],
          'IL' => ['Springfield', 'Chicago'],
          'IN' => ['Indianapolis'],
          'IA' => ['Des Moines'],
          'KS' => ['Topeka', 'Wichita'],
          'KY' => ['Frankfort', 'Louisville'],
          'LA' => ['Baton Rouge', 'New Orleans'],
          'ME' => ['Augusta', 'Portland'],
          'MD' => ['Annapolis', 'Baltimore'],
          'MA' => ['Boston'],
          'MI' => ['Lansing', 'Detroit'],
          'MN' => ['St. Paul', 'Minneapolis'],
          'MS' => ['Jackson'],
          'MO' => ['Jefferson City', 'Kansas City'],
          'MT' => ['Helena', 'Billings'],
          'NE' => ['Lincoln', 'Omaha'],
          'NV' => ['Carson City', 'Las Vegas'],
          'NH' => ['Concord', 'Manchester'],
          'NJ' => ['Trenton', 'Newark'],
          'NM' => ['Santa Fe', 'Albuquerque'],
          'NY' => ['Albany', 'New York'],
          'NC' => ['Raleigh', 'Charlotte'],
          'ND' => ['Bismarck', 'Fargo'],
          'OH' => ['Columbus'],
          'OK' => ['Oklahoma City'],
          'OR' => ['Salem', 'Portland'],
          'PA' => ['Harrisburg', 'Philadelphia'],
          'RI' => ['Providence'],
          'SC' => ['Columbia'],
          'SD' => ['Pierre', 'Sioux Falls'],
          'TN' => ['Nashville', 'Memphis'],
          'TX' => ['Austin', 'Houston'],
          'UT' => ['Salt Lake City'],
          'VT' => ['Montpelier', 'Burlington'],
          'VA' => ['Richmond', 'Virginia Beach'],
          'WA' => ['Olympia', 'Seattle'],
          'WV' => ['Charleston'],
          'WI' => ['Madison', 'Milwaukee'],
          'WY' => ['Cheyenne'],
      }
    end

    def self.recognize(str)
      return if str.blank?

      if str =~ /\b(?:#{states_map.keys.join('|')})\b/o
        $&
      elsif str =~ /\b(?:#{states_map.values.join('|')})\b/o
        states_map.key($&)
      elsif str =~ /\b(?:#{biggest_cities.values.map { |v| v.join('|') }.join('|')})\b/o
        biggest_cities.find { |_k, v| v.include?($&) }&.first
      end
    end
  end
end
