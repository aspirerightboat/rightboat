namespace :google do
  desc 'Generate Google Dynamic Remarketing feed'
  task dynamic_remarketing_csv: :environment do
    Rightboat::GoogleDynamicRemarketing.generate_csv
  end
end
