ActiveAdmin.register MarineEnquiry do

  menu parent: 'Other', priority: 42

  config.sort_order = 'created_at_desc'
end
