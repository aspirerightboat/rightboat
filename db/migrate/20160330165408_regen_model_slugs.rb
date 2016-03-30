class RegenModelSlugs < ActiveRecord::Migration
  def up
    Model.find_each do |model|
      old_slug = model.slug
      res = model.send(:regenerate_slug)
      puts "#{old_slug} => #{model.slug}" if res
    end
  end
end
