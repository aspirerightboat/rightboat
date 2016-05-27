namespace :saved_search_notifier do
  desc 'Alert users about new listings in their saved searches'
  task send_mails: :environment do
    Rightboat::SavedSearchNotifier.new.send_mails
  end

end
