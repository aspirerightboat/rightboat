require 'open_marine'

namespace :export do
  desc 'Export boats in OpenMarine format'
  task openmarine: :environment do
    export_users_ids = [
        18, # Boats.co.uk
        276, # Broadland Yacht Brokers
        33, # Cobra Ribs
        #000, # Cornish Crabber
        52, # Liberty Yachts
        262, # York Marina
    ]
    User.find(export_users_ids).each do |user|
      export_user_boats(user)
    end
  end

  def export_user_boats(user)
    dir = FileUtils.mkdir_p("#{Rails.root}/public/exports").first

    om = OpenMarine.new(target: File.open("#{dir}/#{user.slug}-#{user.broker_info.unique_hash}.xml", 'w+'))
    om.begin do
      om.add_broker do
        om.add_offices(user)
        om.add_boats(user)
      end
    end
  end
end
