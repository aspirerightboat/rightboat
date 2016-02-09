require 'rightboat/exports/open_marine'

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
    User.includes(:broker_info).find(export_users_ids).each do |user|
      Rightboat::Exports::OpenMarine.export_user_boats(user)
    end
  end
end
