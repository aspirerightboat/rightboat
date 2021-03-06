namespace :saved_searches do
  desc 'create saved searches for all users based on their leads'
  task create_from_leads: :environment do
    searches_created = 0

    Lead.where.not(user: nil).where(status: %w(pending cancelled invoiced)).find_each do |lead|
      boat = lead.boat
      user = lead.user
      res = SavedSearch.safe_create(user, manufacturers: [boat.manufacturer_id], models: [boat.model_id])
      searches_created += 1 if res
    end

    puts "#{searches_created} Saved Searches was created"
  end
end
