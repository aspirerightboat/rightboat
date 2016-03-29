class GenerateNewBoatSlugs < ActiveRecord::Migration
  def up
    Boat.not_deleted.find_each do |boat|
      boat.old_slugs.create!(slug: boat.slug)
      boat.slug = nil
      boat.save!
    end
  end
end
