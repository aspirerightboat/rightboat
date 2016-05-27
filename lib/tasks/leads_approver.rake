namespace :leads_approver do
  desc 'Approve pending leads older than 3 days'
  task :approve_recent do
    Rightboat::LeadsApprover.approve_recent
  end
end
