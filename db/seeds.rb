# Currencies what we are supporting
require 'mechanize'

user = User.find_or_initialize_by(email: 'xmpolaris@gmail.com')
user.update_attributes!(
  role: 'ADMIN',
  username: 'xmpolaris',
  first_name: 'Chen',
  last_name: 'ZX',
  password: 'password'
)

doc = Mechanize.new.get("http://www.currenciesdirect.com/common/rates.aspx?code=A04190&pass=A04190&base=GBP")

currency_rates = doc.search("price_history").inject({}) do |h, price|
  unit_name = price.css('unit').first.content
  h[unit_name] = price.css('rate').first.content.to_f
  h
end

YAML.load_file(Rails.root.join("db/data/iso4217.yaml")).each do |code, currency_data|
  currency = Currency.where(name: code).first_or_initialize
  next unless currency.rate = currency_rates[code]
  currency.symbol = currency_data['symbol'] || code
  currency.save!
end

YAML.load_file(Rails.root.join("db/data/countries.yaml")).each do |code|
  country_data = YAML.load_file(Rails.root.join("db/data/countries/#{code}.yaml"))[code]
  name = country_data["names"].shift
  country = Country.where(name: name).first_or_initialize
  country.iso = country_data["alpha2"]
  country.country_code = country_data["country_code"]
  country.currency ||= Currency.where(name: country_data['currency']).first
  country.save!

  country_data["names"].each do |alias_name|
    country.misspellings.where(alias_string: alias_name).first_or_create
  end
end

spec_names = [
  {name: 'length_m',            display_name: 'Length(m)'},
  {name: 'engine_count',        display_name: 'Engine Count'},
  {name: 'engine_hours',        display_name: 'Engine Hours'},
  {name: 'lwl_m',               display_name: 'LWL(m)'},
  {name: 'draft_m',             display_name: 'Draft(m)'},
  {name: 'beam_m',              display_name: 'Beam(m)'},
  {name: 'engine_horse_power',  display_name: 'Engine Horse Power'},
  {name: 'max_speed',           display_name: 'Max Speed'},
  {name: 'cruising_speed',      display_name: 'Cruising Speed'},
  {name: 'dry_weight',          display_name: 'Dry Weight'},
  {name: 'displacement_kgs',    display_name: 'Displacement(kgs)'},
  {name: 'ballast',             display_name: 'Ballast'},
  {name: 'hull_material',       display_name: 'Hull Material'},
  {name: 'electrical_circuit',  display_name: 'Electrical Circuit'},
  {name: 'berths',              display_name: 'Berths'},
  {name: 'single_berths',       display_name: 'Single Berths'},
  {name: 'double_berths',       display_name: 'Double Berths'},
  {name: 'heads',               display_name: 'No of Heads'},
  {name: 'cabins',              display_name: 'Cabins'},
  {name: 'engine_type',         display_name: 'Engine Type'},
  {name: 'keel',                display_name: 'Keel'},
  {name: 'propeller',           display_name: 'Propeller'},
  {name: 'fresh_water_tanks',   display_name: 'Fresh Water Tanks'},
  {name: 'holding_tanks',       display_name: 'Holding Tanks'},
  {name: 'fuel_tanks',          display_name: 'Fuel Tanks'},
  {name: 'designer',            display_name: 'Designer'},
  {name: 'hull_shape',          display_name: 'Hull Shape'},
  {name: 'head_room',           display_name: 'Head Room'},
  {name: 'builder',             display_name: 'Builder'},
  {name: 'length_on_deck',      display_name: 'Length on Deck'},
  {name: 'hull_type',           display_name: 'Hull Type'},
  {name: 'number_on_cabins',    display_name: 'Number on Cabins'},
  {name: 'number_on_berths',    display_name: 'Number on Berths'},
]
spec_names.each do |attrs|
  spec = Specification.where(name: attrs[:name]).first_or_initialize
  spec.update_attributes(attrs)
end

RBConfig.repair