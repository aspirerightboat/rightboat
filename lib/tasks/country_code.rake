desc "Add country code to countries"
task :country_code => :environment do
  YAML.load_file(Rails.root.join("db/data/countries.yaml")).each do |code|
    country_data = YAML.load_file(Rails.root.join("db/data/countries/#{code}.yaml"))[code]
    if country = Country.find_by(iso: code)
      country.update country_code: country_data['country_code']
    end
  end
end
