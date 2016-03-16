namespace :manufacturers do
  task :txt do
    open("tmp/manufacturers-#{Time.current.strftime('%Y-%m-%d')}.txt", 'w') do |f|
      Manufacturer.order(:name).pluck(:name).each { |name| f.puts name }
    end
  end
end