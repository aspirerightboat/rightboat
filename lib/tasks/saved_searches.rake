namespace :saved_searches do
  desc 'create saved searches for all users based on their leads'
  task create_from_leads: :environment do
    searches_created = 0

    Lead.where.not(user: nil).where(status: %w(pending rejected invoiced)).find_each do |lead|
      boat = lead.boat
      user = lead.user
      res = SavedSearch.create_and_run(user, manufacturers: [boat.manufacturer_id.to_s], models: [boat.model_id.to_s])
      searches_created += 1 if res
    end

    puts "#{searches_created} Saved Searches was created"
  end
end
